# Copyright 2018 The Bazel Authors. All rights reserved.
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

load("//kotlin/internal/common:common.bzl", _common = "common")
load("//kotlin/internal:defs.bzl", _KT_COMPILER_REPO = "KT_COMPILER_REPO", _TOOLCHAIN_TYPE = "TOOLCHAIN_TYPE")

"""Kotlin Toolchains

This file contains macros for defining and registering specific toolchains.

### Examples

To override a tool chain use the appropriate macro in a `BUILD` file to declare the toolchain:

```bzl
load("@io_bazel_rules_kotlin//kotlin:toolchains.bzl", "define_kt_toolchain")

define_kt_toolchain(
    name= "custom_toolchain",
    api_version = "1.1",
    language_version = "1.1",
)
```
and then register it in the `WORKSPACE`:
```bzl
register_toolchains("//:custom_toolchain")
```
"""

def _kotlin_toolchain_impl(ctx):
    toolchain = dict(
        label = _common.restore_label(ctx.label),
        language_version = ctx.attr.language_version,
        api_version = ctx.attr.api_version,
        coroutines = ctx.attr.coroutines,
        debug = ctx.attr.debug,
        jvm_target = ctx.attr.jvm_target,
        kotlinbuilder = ctx.attr.kotlinbuilder,
        kotlin_home = ctx.attr.kotlin_home,
        jvm_stdlibs = java_common.create_provider(
            compile_time_jars = ctx.files.jvm_stdlibs,
            runtime_jars = ctx.files.jvm_runtime,
            use_ijar = False,
        ),
    )
    return [
        platform_common.ToolchainInfo(**toolchain),
    ]

kt_toolchain = rule(
    doc = """The kotlin toolchain. This should not be created directly `define_kt_toolchain` should be used. The
    rules themselves define the toolchain using that macro.""",
    attrs = {
        "kotlin_home": attr.label(
            doc = "the filegroup defining the kotlin home",
            default = Label("@" + _KT_COMPILER_REPO + "//:home"),
            allow_files = True,
        ),
        "kotlinbuilder": attr.label(
            doc = "the kotlin builder executable",
            default = Label("//kotlin/builder"),
            executable = True,
            allow_files = True,
            cfg = "host",
        ),
        "language_version": attr.string(
            doc = "this is the -languag_version flag [see](https://kotlinlang.org/docs/reference/compatibility.html)",
            default = "1.2",
            values = [
                "1.1",
                "1.2",
            ],
        ),
        "api_version": attr.string(
            doc = "this is the -api_version flag [see](https://kotlinlang.org/docs/reference/compatibility.html).",
            default = "1.2",
            values = [
                "1.1",
                "1.2",
            ],
        ),
        "debug": attr.string_list(
            doc = """Debugging tags passed to the builder. Two tags are supported. `timings` will cause the builder to
            print timing information. `trace` will cause the builder to print tracing messages. These tags can be
            enabled via the defines `kt_timings=1` and `kt_trace=1`. These can also be enabled on a per target bases by
            using `tags` attribute defined directly on the rules.""",
            allow_empty = True,
        ),
        "coroutines": attr.string(
            doc = "the -Xcoroutines flag, enabled by default as it's considered production ready 1.2.0 onward.",
            default = "enable",
            values = [
                "enable",
                "warn",
                "error",
            ],
        ),
        "jvm_runtime": attr.label(
            doc = "The implicit jvm runtime libraries. This is internal.",
            default = Label("@" + _KT_COMPILER_REPO + "//:kotlin-runtime"),
            providers = [JavaInfo],
            cfg = "target",
        ),
        "jvm_stdlibs": attr.label_list(
            doc = "The jvm stdlibs. This is internal.",
            default = [
                Label("@" + _KT_COMPILER_REPO + "//:kotlin-stdlib"),
                Label("@" + _KT_COMPILER_REPO + "//:kotlin-stdlib-jdk7"),
                # JDK8 is being added blindly but I think we will probably not support bytecode levels 1.6 when the
                # repo stabelizes so this should be fine.
                Label("@" + _KT_COMPILER_REPO + "//:kotlin-stdlib-jdk8"),
            ],
            providers = [JavaInfo],
            cfg = "target",
        ),
        "jvm_target": attr.string(
            doc = "the -jvm_target flag. This is only tested at 1.8.",
            default = "1.8",
            values = [
                "1.6",
                "1.8",
            ],
        ),
    },
    implementation = _kotlin_toolchain_impl,
    provides = [platform_common.ToolchainInfo],
)

def kt_register_toolchains():
    """This macro registers all of the default toolchains."""
    native.register_toolchains("@io_bazel_rules_kotlin//kotlin/internal:default_toolchain")

def define_kt_toolchain(
        name,
        language_version = None,
        api_version = None,
        jvm_target = None,
        coroutines = None,
        debug = []):
    """Define a Kotlin JVM Toolchain, the name is used in the `toolchain` rule so can be used to register the toolchain
    in the WORKSPACE file.
    """
    impl_name = name + "_impl"
    kt_toolchain(
        name = impl_name,
        language_version = language_version,
        api_version = api_version,
        jvm_target = jvm_target,
        coroutines = coroutines,
        debug = debug,
        visibility = ["//visibility:public"],
    )
    native.toolchain(
        name = name,
        toolchain_type = _TOOLCHAIN_TYPE,
        toolchain = impl_name,
        visibility = ["//visibility:public"],
    )
