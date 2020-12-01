package io.bazel.kotlin.plugin.jdeps

import org.jetbrains.kotlin.config.CompilerConfigurationKey

object JdepsGenConfigurationKeys {
  /**
   * Output path of generated Jdeps proto file.
   */
  val OUTPUT_JDEPS: CompilerConfigurationKey<String> =
    CompilerConfigurationKey.create(JdepsGenCommandLineProcessor.OUTPUT_JDEPS_FILE_OPTION.description)

  /**
   * Label of the Bazel target being analyzed.
   */
  val TARGET_LABEL: CompilerConfigurationKey<String> =
    CompilerConfigurationKey.create(JdepsGenCommandLineProcessor.TARGET_LABEL_OPTION.description)
}
