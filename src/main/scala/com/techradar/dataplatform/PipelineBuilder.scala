package com.techradar.dataplatform

import com.syedatifakhtar.pipelines.Pipelines.Pipeline
import com.syedatifakhtar.scalaterraform.TerraformPipelines.TerraformStep
import com.syedatifakhtar.scalaterraform.{DefaultConfigArgsResolver, TerraformModule, TerraformPipelines}
import com.typesafe.config.{Config, ConfigFactory}

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

  private def buildPipelineMap(pipelines: Pipeline*): Map[String, Pipeline] = {
    pipelines.map { p => p.name -> p }.toMap
  }

  def getModule(moduleName: String) = {
    TerraformModule(srcDir, buildDir)(moduleName)(configResolverBuilder(moduleName))
  }

  def getPipelines(command: String): Map[String, Pipeline] = {
    val accountStep = TerraformStep(getModule("account")) _
    val environmentStep = TerraformStep(getModule("environment")) _
    val platformModule = getModule("platform")
    val platformStep = TerraformStep(platformModule) _
    val accountPipeline = TerraformPipelines
      .TerraformPipeline
      .empty("account", command) ->
      accountStep
    val environmentPipeline = TerraformPipelines
      .TerraformPipeline
      .empty("environment", command) ->
      environmentStep
    val allInfra = TerraformPipelines
      .TerraformPipeline
      .empty("all_infra", command) ->
      platformStep


    buildPipelineMap(accountPipeline,environmentPipeline)
  }

}
