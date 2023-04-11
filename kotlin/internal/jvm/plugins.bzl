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
KtJvmPluginInfo = provider(
    doc = "This provider contains the plugin info for the JVM aspect",
    fields = {
        "annotation_processors": "depset of structs containing annotation processor definitions",
        "transitive_runtime_jars": "depset of transitive_runtime_jars for this plugin and deps",
    },
)

_EMPTY_PLUGIN_INFO = [KtJvmPluginInfo(annotation_processors = depset(), transitive_runtime_jars = depset())]

# Mapping functions for args.add_all.
# These preserve the transitive depsets until needed.
def _kt_plugin_to_processor(processor):
    if hasattr(java_common, "JavaPluginInfo"):
        return processor.processor_classes.to_list()
    return processor.processor_class

def _kt_plugin_to_processorpath(processor):
    if hasattr(java_common, "JavaPluginInfo"):
        return [j.path for j in processor.processor_jars.to_list()]
    return [j.path for j in processor.classpath.to_list()]

def _targets_to_annotation_processors(targets):
    if hasattr(java_common, "JavaPluginInfo"):
        _JavaPluginInfo = getattr(java_common, "JavaPluginInfo")
        plugins = []
        for t in targets:
            if _JavaPluginInfo in t:
                p = t[_JavaPluginInfo].plugins
                if p.processor_jars:
                    plugins.append(p)
            elif JavaInfo in t:
                p = t[JavaInfo].plugins
                if p.processor_jars:
                    plugins.append(p)
        return depset(plugins)

    return depset(transitive = [t[KtJvmPluginInfo].annotation_processors for t in targets if KtJvmPluginInfo in t])

def _targets_to_annotation_processors_java_plugin_info(targets):
    if hasattr(java_common, "JavaPluginInfo"):
        _JavaPluginInfo = getattr(java_common, "JavaPluginInfo")
        return [t[_JavaPluginInfo] for t in targets if _JavaPluginInfo in t]
    return [t[JavaInfo] for t in targets if JavaInfo in t]

def _targets_to_transitive_runtime_jars(targets):
    if hasattr(java_common, "JavaPluginInfo"):
        _JavaPluginInfo = getattr(java_common, "JavaPluginInfo")
        return depset(
            transitive = [
                (t[_JavaPluginInfo] if _JavaPluginInfo in t else t[JavaInfo]).plugins.processor_jars
                for t in targets
                if _JavaPluginInfo in t or JavaInfo in t
            ],
        )
    return depset(transitive = [t[KtJvmPluginInfo].transitive_runtime_jars for t in targets if KtJvmPluginInfo in t])

mappers = struct(
    targets_to_annotation_processors = _targets_to_annotation_processors,
    targets_to_annotation_processors_java_plugin_info = _targets_to_annotation_processors_java_plugin_info,
    targets_to_transitive_runtime_jars = _targets_to_transitive_runtime_jars,
    kt_plugin_to_processor = _kt_plugin_to_processor,
    kt_plugin_to_processorpath = _kt_plugin_to_processorpath,
)

def merge_plugin_infos(attrs):
    """Merge all of the plugin infos found in the provided sequence of attributes.
    Returns:
        A KtJvmPluginInfo provider, Each of the entries is serializable."""
    return KtJvmPluginInfo(
        annotation_processors = _targets_to_annotation_processors(attrs),
        transitive_runtime_jars = _targets_to_transitive_runtime_jars(attrs),
    )
