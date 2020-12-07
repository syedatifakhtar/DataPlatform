package com.techradar.dataplatform

import java.io.{File, PrintWriter}

import com.syedatifakhtar.pipelines.Pipelines.{MultiSequencePipeline, Pipeline, UnitStep}
import com.syedatifakhtar.scalaterraform.TerraformPipelines.TerraformStep
import com.syedatifakhtar.scalaterraform.{DefaultConfigArgsResolver, TerraformModule, TerraformPipelines}
import com.typesafe.config.{Config, ConfigFactory}

import scala.sys.process.Process
import scala.util.Try

object PipelineBuilder {

  object PlatformInfraConfig {
    val config: Config = ConfigFactory.load("conf/platform.conf")
  }


  private def configValueResolver = {
    import scala.collection.JavaConverters._
    path: String =>
      Try {
        PlatformInfraConfig
          .config
          .getConfig(path)
          .entrySet()
          .asScala.map(x => (x.getKey, x.getValue.unwrapped.toString))
          .toMap
      }.toOption
  }

  private val configTree = "techradar-data-platform.infra"

  private def configResolverBuilder = DefaultConfigArgsResolver(configValueResolver)(configTree) _

  val srcDir = s"${this.getClass.getClassLoader().getResource("terraform").getPath}"
  val buildDir = s"${this.getClass.getClassLoader().getResource("terraform").getPath}/build"

  def getModule(moduleName: String) = {
    TerraformModule(srcDir, buildDir)(moduleName)(configResolverBuilder(moduleName)(None))
  }

  def getModuleWithOverrideValues(moduleName: String, overrides: => Map[String, Map[String, String]]) = {
    TerraformModule(srcDir, buildDir)(moduleName)(configResolverBuilder(moduleName)(Some(overrides)))
  }


  def saveEMRSSHKey(keyOutput: String, masterNodeDNS: String) = {
    val credentialsDir = s"${buildDir}/.keys"
    val credsDir = new File(credentialsDir)
    if (!credsDir.exists()) {
      credsDir.mkdirs()
    }
    val sshKeyLocation = s"$credentialsDir/masterNodeKey.pem"
    val writer = new PrintWriter(sshKeyLocation) {
      write(keyOutput);
      close()
    }
    Process(s"chmod -R 700 $credentialsDir/masterNodeKey.pem").!!
    if (writer.checkError()) throw new Exception("Failed to write emr ssh key!")
    println(s"Key written to ${sshKeyLocation}")
    println(s"You may now ssh to master node using: ssh -i ${sshKeyLocation} hadoop@${masterNodeDNS}")
    println(s"You may now connect to zeppelin using ssh hadoop@${masterNodeDNS} -i ${sshKeyLocation} -L 8890:127.0.0.1:8890 ")
  }

  def getPipelines(command: String) = {
    val accountStep = TerraformStep(getModule("account")) _
    val environmentStep = TerraformStep(getModule("environment")) _

    lazy val platformDeltaLakeModule = getModuleWithOverrideValues("platform_deltalake", {
      lazy val environmentOutput = getModule("environment").output
      Map(
        "vars" -> Map(
          "main_subnet_id" -> environmentOutput.get("subnet_public_1_id"),
          "security_group_id" -> environmentOutput.get("security_group_id")
        )
      )
    })

    lazy val platformDremioModule = getModuleWithOverrideValues("platform_dremio", {
      lazy val environmentOutput = getModule("environment").output
      Map(
        "vars" -> Map(
          "eks_subnet_ids" -> s"${environmentOutput.get("subnet_private_1_id")},${environmentOutput.get("subnet_private_2_id")}",
          "security_group_ids" -> environmentOutput.get("security_group_id")
        )
      )
    })

    lazy val platformDremioStep = TerraformStep(platformDremioModule) _

    lazy val platformDeltaLakeStep = TerraformStep(platformDeltaLakeModule) _
    lazy val accountPipeline = { () =>
      TerraformPipelines
        .TerraformPipeline
        .empty("account", command) ->
        accountStep
    }
    lazy val generateEMRKey = { () =>
      TerraformPipelines.TerraformPipeline.empty("generateEMRKey", "") ->
        UnitStep("Fetch EMR Key") {
          pc =>
            val emrOutput = platformDeltaLakeModule.output
            saveEMRSSHKey(emrOutput.get("emr_ssh_key"), emrOutput.get("emr_master_node_dns"))
            Map.empty[String, String]
        }
    }
    lazy val environmentPipeline = { () =>
      TerraformPipelines
        .TerraformPipeline
        .empty("environment", command) ->
        environmentStep
    }
    lazy val platformDeltaLakePipeline = { () =>
      TerraformPipelines.TerraformPipeline.empty("platform_deltalake", command) ->
        platformDeltaLakeStep ->
        generateEMRKey
    }

    lazy val platformDremioPipeline = { () =>
      TerraformPipelines.TerraformPipeline.empty("platform_dremio", command) ->
        platformDremioStep
    }
    lazy val allInfra = {
      { () =>
        println("All Infra step called!")
        MultiSequencePipeline
          .empty("all_infra") ->
          environmentPipeline ->
          platformDeltaLakePipeline ->
          generateEMRKey ->
          platformDremioPipeline
      }
    }


    val pipelineMap: Map[String, () => Pipeline] = Map("account" -> accountPipeline
      , "environment" -> environmentPipeline
      , "platformDeltaLake" -> platformDeltaLakePipeline
      , "generateEMRKey" -> generateEMRKey
      , "allInfra" -> allInfra
    )
    pipelineMap
  }

}
