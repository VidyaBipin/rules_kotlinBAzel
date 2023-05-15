package io.bazel.kotlin.generate

import io.bazel.kotlin.generate.WriteKotlincCapabilities.KotlincCapabilities.Companion.asCapabilities
import org.jetbrains.kotlin.cli.common.arguments.Argument
import org.jetbrains.kotlin.cli.common.arguments.K2JVMCompilerArguments
import org.jetbrains.kotlin.config.LanguageVersion
import java.nio.file.FileSystems
import java.nio.file.Files
import java.time.Year
import kotlin.io.path.exists
import kotlin.io.path.writeText

/**
 * Generates a list of kotlinc flags from the K2JVMCompilerArguments on the classpath.
 */
object WriteKotlincCapabilities {

  @JvmStatic
  fun main(vararg args: String) {
    // TODO: Replace with a real option parser
    val options = args.asSequence()
      .flatMap { t -> t.split("=", limit = 1) }
      .chunked(2)
      .fold(mutableMapOf<String, MutableList<String>>()) { m, (key, value) ->
        m.apply {
          computeIfAbsent(key) { mutableListOf() }.add(value)
        }
      }

    val instance = K2JVMCompilerArguments()

    val capabilitiesName = LanguageVersion.LATEST_STABLE.run {
      "capabilities_${major}.${minor}.bzl.com_github_jetbrains_kotlin.bazel"
    }


    val env_pattern = Regex("\\$\\{(\\w+)}")
    val capabilitiesDirectory = options["--out"]
      ?.first()
      ?.let { env ->
        env_pattern.replace(env) {
          System.getenv(it.groups[1]?.value)
        }
      }
      ?: error("--out is required")

    FileSystems.getDefault()
      .getPath("$capabilitiesDirectory/$capabilitiesName")
      .apply {
        if (!parent.exists()) {
          Files.createDirectories(parent)
        }
        writeText(
          K2JVMCompilerArguments::class.members.asSequence()
            .map { member ->
              member.annotations.find { it is Argument }?.let { argument ->
                member to (argument as Argument)
              }
            }
            .filterNotNull()
            .map { (member, argument) ->
              KotlincCapability(
                flag = argument.value,
                default = "${member.call(instance)}",
                type = member.returnType.toString(),
              )
            }.asCapabilities().asCapabilitiesBzl(),
        )
      }
      .let {
        println("Wrote to $it")
      }
  }

  private class KotlincCapabilities(capabilities: Iterable<KotlincCapability>) :
    List<KotlincCapability> by capabilities.toList() {

    companion object {
      fun Sequence<KotlincCapability>.asCapabilities() = KotlincCapabilities(toList())
    }

    fun asCapabilitiesBzl() = HEADER + "\n" + joinToString(
      ",\n    ",
      prefix = "KOTLIN_OPTS = [\n    ",
      postfix = "\n]",
      transform = KotlincCapability::asCapabilityFlag,
    )
  }

  private data class KotlincCapability(
    private val flag: String,
    private val default: String,
    private val type: String,
  ) {
    fun asCapabilityFlag() = "\"${flag}\""
  }


  private val HEADER = """
    # Copyright ${Year.now()} The Bazel Authors. All rights reserved.
    #
    # Licensed under the Apache License, Version 2.0 (the "License");
    # you may not use this file except in compliance with the License.
    # You may obtain a copy of the License at
    #
    #    http://www.apache.org/licenses/LICENSE-2.0
    #
    # Unless required by applicable law or agreed to in writing, software
    # distributed under the License is distributed on an "AS IS" BASIS,
    # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    # See the License for the specific language governing permissions and
    # limitations under the License.
  """.trimIndent()
}
