/*
 * Copyright 2020 The Bazel Authors. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

package io.bazel.worker

import io.bazel.worker.WorkerContext.TaskContext

/** Worker executes a unit of Work */
interface Worker {
  companion object {
    fun from(args:Iterable<String>, then:Worker.(Iterable<String>) -> Int):Int {
      val worker = when {
        "--persistent_worker" in args -> PersistentWorker()
        else -> InvocationWorker()
      }
      return worker.then(args.filter { it != "--persistent_worker" })
    }
  }

  fun start(arguments: Iterable<String>, execute: Work): Int

  fun start(
    arguments: Iterable<String> = emptyList(),
    execute: (ctx: TaskContext, args: Iterable<String>) -> Status
  ) = start(
    arguments,
    object : Work {
      override fun invoke(ctx: TaskContext, args: Iterable<String>) = execute(ctx, args)
    })
}
