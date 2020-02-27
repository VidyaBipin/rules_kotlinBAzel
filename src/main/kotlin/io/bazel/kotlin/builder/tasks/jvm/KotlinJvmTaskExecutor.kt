/*
 * Copyright 2018 The Bazel Authors. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package io.bazel.kotlin.builder.tasks.jvm

import io.bazel.kotlin.builder.toolchain.CompilationTaskContext
import io.bazel.kotlin.builder.toolchain.KotlinCompilerPluginArgsEncoder
import io.bazel.kotlin.builder.toolchain.KotlinToolchain
import io.bazel.kotlin.model.JvmCompilationTask
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Due to an inconsistency in the handling of -Xfriends-path, jvm uses a comma (property list
 * separator), js uses the system path separator.
 */
const val X_FRIENDS_PATH_SEPARATOR = ","

@Singleton
class KotlinJvmTaskExecutor @Inject internal constructor(
  private val compiler: KotlinToolchain.KotlincInvoker,
  private val pluginArgsEncoder: KotlinCompilerPluginArgsEncoder,
  private val javaCompiler: JavaCompiler,
  private val jDepsGenerator: JDepsGenerator
) {
  fun execute(context: CompilationTaskContext, task: JvmCompilationTask) {
    val preprocessedTask = task.preProcessingSteps(context, pluginArgsEncoder, compiler)
    context.execute("compile classes") {
      preprocessedTask.compileAll(context, compiler, javaCompiler)
    }

    context.execute("create jar") { preprocessedTask.createOutputJar() }
    context.execute("produce src jar") { preprocessedTask.produceSourceJar() }
    context.execute("generate jdeps") { jDepsGenerator.generateJDeps(preprocessedTask) }
  }
}
