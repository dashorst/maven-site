---
title: toolchains.xml
summary: Where Maven reads toolchains.xml, the elements of a JDK toolchain, how a requirement matches an entry, and which plugins use the selected toolchain.
type: reference
since: 3.9
keywords: toolchains file location, global toolchains, user toolchains, version range, vendor, JDK discovery, discovered-jdk-toolchains-cache.xml, toolchain-aware plugins, Misconfigured toolchains, No toolchain matched
terms: toolchains.xml | <toolchains> | <toolchain> | <type> | <provides> | <configuration> | <jdkHome> | -t | --toolchains | -gt | --global-toolchains | -it | --install-toolchains | maven.user.toolchains | maven.installation.toolchains | jdkToolchain | select-jdk-toolchain | toolchain.jdk.version
---

<!--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->


*toolchains.xml* describes the tools installed on a machine, most often JDKs, so that a build can ask for one without naming its path. [Toolchains and the JDK Maven runs on](toolchains.html) explains the idea; [Build with a different JDK than Maven runs on](build-with-another-jdk.html) puts it to use.

## Where Maven reads it

Maven reads two files and puts their toolchains in one list, those of the user file first.

| File | Default location | Command-line option | Property |
|---|---|---|---|
| User | *~/.m2/toolchains.xml* | `-t`, `--toolchains` | `maven.user.toolchains` (Maven 4) |
| Global | *conf/toolchains.xml* in the Maven installation | `-gt`, `--global-toolchains` | |

A file in a default location that does not exist is skipped. A file named with `-t` or `-gt` must exist, or Maven stops with `The specified user toolchains file does not exist` or `The specified global toolchains file does not exist`. The global file that comes with Maven contains only comments, so out of the box all toolchains come from the user file.

> **Maven 4:** The global file is called the installation file. Its option is `-it` or `--install-toolchains`, and its property `maven.installation.toolchains`. `-gt` still works, with a warning that it is deprecated. A missing file named with either option stops Maven with `The specified installation toolchains file does not exist`.

## Elements

*~/.m2/toolchains.xml*

```xml
<toolchains>
  <toolchain>
    <type>jdk</type>
    <provides>
      <version>17</version>
      <vendor>temurin</vendor>
    </provides>
    <configuration>
      <jdkHome>/opt/jdk/temurin-17</jdkHome>
    </configuration>
  </toolchain>
</toolchains>
```

| Element | Contains |
|---|---|
| `<toolchains>` | The root element. Zero or more `<toolchain>` elements. |
| `<toolchain>` | One installed tool. |
| `<type>` | The kind of tool. `jdk` for a JDK; plugins that bring their own toolchain type define other values, such as `protobuf`. |
| `<provides>` | Labels that requirements are matched against, one element per label: `<version>`, `<vendor>`, or any name you choose, such as `<id>`. The values are yours; Maven does not read them from the tool. |
| `<configuration>` | Where the tool is. Its content depends on the type. |
| `<jdkHome>` | For type `jdk`: the JDK's home directory, the directory that contains `bin/javac`. When it does not exist, the toolchains plugin stops with `Misconfigured toolchains. Non-existing JDK home configuration at` and the path. |

The root element may carry the namespace `http://maven.apache.org/TOOLCHAINS/1.1.0`, which Maven 3 uses, or `http://maven.apache.org/TOOLCHAINS/1.2.0`, which Maven 4 uses, or none. Maven 3.9, 3.10 and 4.0 read all three forms.

## How requirements match

A requirement is the set of labels a project asks for, in the configuration of the toolchains plugin or in a plugin's `jdkToolchain` parameter:

*pom.xml*

```xml
<toolchains>
  <jdk>
    <version>[11,18)</version>
    <vendor>temurin</vendor>
  </jdk>
</toolchains>
```

- The element name, here `jdk`, is the toolchain type.
- Every label in the requirement must match the label of the same name in `<provides>`. Labels the requirement does not mention are not checked.
- `version` is compared as a version. A single version matches only the same version: `17` matches `17`, but not `17.0.20`, and `8` does not match `1.8`. A range, such as `[17,18)`, `[11,)` or `(,11]`, matches every version inside it: `[17,18)` matches `17` and `17.0.20`, and `[1.8,9)` matches `1.8`.
- Every other label is compared as text, ignoring case: `Temurin` matches `temurin`.
- When several toolchains match, the first one in the list is used: the user file before the global file, and within a file from top to bottom.

When no toolchain matches, the toolchains plugin stops the build:

```
[ERROR] No toolchain matched from 3 found for type jdk
[ERROR] Cannot find matching toolchain definitions for the following toolchain types:
jdk [ version='25' ]
```

## Discovered JDK toolchains

The `select-jdk-toolchain` goal of the maven-toolchains-plugin, since version 3.2.0, matches its requirement against the entries of *toolchains.xml* and against the JDKs it discovers. It finds JDKs through:

- the environment variables `JAVA_HOME` and `JAVA<n>_HOME`, such as `JAVA17_HOME`;
- the JDK Maven runs on;
- the directories of installers in your home directory: *.sdkman/candidates/java*, *.jdks*, *.m2/jdks*, *.gradle/jdks*, *.jenv/versions*, *.jbang/cache/jdks*, *.asdf/installs/java*, *.jabba/jdk*, *.local/share/mise/installs/java*;
- on macOS, */Library/Java/JavaVirtualMachines* and *~/Library/Java/JavaVirtualMachines*;
- on Windows, the directories of Amazon Corretto, BellSoft, Eclipse Adoptium, Java and Zulu under *C:\Program Files*, and the JDKs installed with Scoop;
- on other systems, */usr/jdk*, */usr/java*, */usr/local/java*, */opt/java*, */usr/lib/jvm* and */usr/lib64/jvm*;
- the tool cache of GitHub Actions runners.

A directory without `bin/javac` is skipped. The goal keeps what it found in *~/.m2/discovered-jdk-toolchains-cache.xml*.

A discovered JDK provides these labels, read from the JDK itself:

| Label | Example |
|---|---|
| `version` | `17.0.20`; Java 8 reports `1.8.0_504` |
| `runtime.name` | `OpenJDK Runtime Environment` |
| `runtime.version` | `17.0.20+8` |
| `vendor` | `Eclipse Adoptium` |
| `vendor.version` | `Temurin-17.0.20+8` |
| `current` | `true` for the JDK Maven runs on |
| `lts` | `true` for a long-term support release |
| `env` | The environment variables that point to it, such as `JAVA17_HOME` |

The goal takes its requirement from these parameters:

| Parameter | Property | Meaning |
|---|---|---|
| `version` | `toolchain.jdk.version` | A version range, such as `[17,18)`. A single version such as `17` does not match `17.0.20`. |
| `vendor` | `toolchain.jdk.vendor` | The vendor. |
| `runtimeName` | `toolchain.jdk.runtime.name` | The runtime name. |
| `runtimeVersion` | `toolchain.jdk.runtime.version` | The runtime version. |
| `env` | `toolchain.jdk.env` | The name of an environment variable that must point to the JDK, such as `JAVA17_HOME`. |
| `useJdk` | `toolchain.jdk.mode` | `IfMatch` (default): select no toolchain when the JDK Maven runs on matches. `IfSame`: select no toolchain when the best match is the JDK Maven runs on. `Never`: always select a toolchain. |
| `comparator` | `toolchain.jdk.comparator` | The order of preference among matching JDKs. Default `lts,current,env,version,vendor`. |
| `discoverToolchains` | `toolchain.jdk.discover` | `false` to use only the entries of *toolchains.xml*. Default `true`. |

The plugin's [JDK discovery page](../../plugins/maven-toolchains-plugin/toolchains/jdk-discovery.html) and the [description of the goal](../../plugins/maven-toolchains-plugin/select-jdk-toolchain-mojo.html) have the details. The goals `display-discovered-jdk-toolchains` and `generate-jdk-toolchains-xml` print the discovered JDKs, the second one in the format of *toolchains.xml*.

## Plugins that use toolchains

These plugins use the JDK toolchain selected for the module. The plugins with a version in the last column also accept a requirement of their own in a `jdkToolchain` parameter, which overrides the module's selection for that plugin and is matched against *toolchains.xml* only.

| Plugin | Uses the selected JDK since | `jdkToolchain` since |
|---|---|---|
| [maven-compiler-plugin](../../plugins/maven-compiler-plugin/) | 2.1 | 3.6.0 |
| [maven-surefire-plugin](../../surefire/maven-surefire-plugin/) | 2.4.3 | 3.0.0-M5 |
| [maven-failsafe-plugin](../../surefire/maven-failsafe-plugin/) | 2.5 | 3.0.0-M5 |
| [maven-javadoc-plugin](../../plugins/maven-javadoc-plugin/) | 2.5 | 3.0.0 |
| [maven-jarsigner-plugin](../../plugins/maven-jarsigner-plugin/) | 1.3 | |
| [maven-pmd-plugin](../../plugins/maven-pmd-plugin/) | 3.14.0 | 3.14.0 |
| [maven-jar-plugin](../../plugins/maven-jar-plugin/), for the `Build-Jdk-Spec` manifest entry | 3.4.0 | |
| [maven-jlink-plugin](../../plugins/maven-jlink-plugin/) | 3.0.0-alpha-1 | 3.0.0-alpha-1 |
| [maven-jmod-plugin](../../plugins/maven-jmod-plugin/) | 3.0.0-alpha-1 | 3.0.0-alpha-1 |
| [maven-jdeps-plugin](../../plugins/maven-jdeps-plugin/) | 3.0.0 | |
| [maven-jdeprscan-plugin](../../plugins/maven-jdeprscan-plugin/) | 3.0.0-alpha-1 | |
| [exec-maven-plugin](https://www.mojohaus.org/exec-maven-plugin/) (MojoHaus), `exec` goal | 1.1.1 | |
| [animal-sniffer-maven-plugin](https://www.mojohaus.org/animal-sniffer/animal-sniffer-maven-plugin/) (MojoHaus), `build` goal | 1.3 | |
| [cassandra-maven-plugin](https://www.mojohaus.org/cassandra-maven-plugin/) (MojoHaus) | 0.7.0-1 | |
| [keytool-maven-plugin](https://www.mojohaus.org/keytool/) (MojoHaus) | 1.4 to 1.7; not in 2.x | |

The [protobuf-maven-plugin](https://www.xolstice.org/protobuf-maven-plugin/examples/protobuf-toolchain.html) of org.xolstice uses a toolchain of type `protobuf` for the `protoc` compiler, since version 0.5.0. A plugin can define its own toolchain type; see [Custom Toolchains](../../plugins/maven-toolchains-plugin/toolchains/custom.html).
