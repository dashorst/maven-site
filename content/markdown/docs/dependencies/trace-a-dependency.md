---
title: Find out where a dependency comes from
summary: See which of your dependencies brings in a library, which version won and why, and which libraries you use without declaring them.
type: howto
since: 3.9
keywords: dependency graph, transitive dependency, which jar, why is this jar here, wrong version, version conflict, omitted for conflict, omitted for duplicate, version managed from, used undeclared dependencies, unused declared dependencies, NoSuchMethodError, ClassNotFoundException
terms: dependency:tree | dependency:analyze | -Dincludes | -Dverbose | maven-dependency-plugin
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

Use this when a library is on your classpath that you did not ask for, or in a different version than you expected. It often starts with a `NoSuchMethodError` or `ClassNotFoundException` at runtime, or with a security scanner that names a JAR you never declared.

The examples use a project that declares two HTTP clients:

*pom.xml*

```xml
<dependencies>
  <dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
    <version>4.5.14</version>
  </dependency>
  <dependency>
    <groupId>org.apache.httpcomponents.client5</groupId>
    <artifactId>httpclient5</artifactId>
    <version>5.1.4</version>
  </dependency>
</dependencies>
```

## Show the dependency tree

In the directory of the project's *pom.xml*, run:

```
mvn dependency:tree
```

The tree shows every dependency of the project, and under each one the dependencies it brought in, with their versions and scopes:

```
[INFO] com.example:app:jar:1.0-SNAPSHOT
[INFO] +- org.apache.httpcomponents:httpclient:jar:4.5.14:compile
[INFO] |  +- org.apache.httpcomponents:httpcore:jar:4.4.16:compile
[INFO] |  +- commons-logging:commons-logging:jar:1.2:compile
[INFO] |  \- commons-codec:commons-codec:jar:1.11:compile
[INFO] \- org.apache.httpcomponents.client5:httpclient5:jar:5.1.4:compile
[INFO]    +- org.apache.httpcomponents.core5:httpcore5:jar:5.1.5:compile
[INFO]    +- org.apache.httpcomponents.core5:httpcore5-h2:jar:5.1.5:compile
[INFO]    \- org.slf4j:slf4j-api:jar:1.7.25:compile
```

Each line is `groupId:artifactId:type:version:scope`. The project's own dependencies are at the first level; everything below them is a transitive dependency. A library appears once, at the place where Maven took it from. In a multi-module project, the command prints a tree for each module; add `-pl` and the module's directory to see one.

## Show only the paths to one library

To see how a library gets into the project, give its coordinates in `includes`:

```
mvn dependency:tree -Dincludes=commons-codec:commons-codec
```

```
[INFO] com.example:app:jar:1.0-SNAPSHOT
[INFO] \- org.apache.httpcomponents:httpclient:jar:4.5.14:compile
[INFO]    \- commons-codec:commons-codec:jar:1.11:compile
```

The pattern is `groupId:artifactId:type:version`, and every part can be left out or written with `*`: `-Dincludes=commons-codec` matches the group, `-Dincludes=:commons-logging` the artifact, `-Dincludes=org.apache.*` every group under `org.apache`. Separate several patterns with commas. `excludes` takes the same patterns and leaves those libraries out of the tree.

## See which versions lost

The tree shows each library in the version Maven chose. To also see the versions it did not choose, and why, add `verbose`:

```
mvn dependency:tree -Dverbose -Dincludes=commons-codec:commons-codec
```

```
[INFO] com.example:app:jar:1.0-SNAPSHOT
[INFO] +- org.apache.httpcomponents:httpclient:jar:4.5.14:compile
[INFO] |  \- commons-codec:commons-codec:jar:1.11:compile
[INFO] \- org.apache.httpcomponents.client5:httpclient5:jar:5.1.4:compile
[INFO]    \- (commons-codec:commons-codec:jar:1.15:compile - omitted for conflict with 1.11)
```

`httpclient5` asks for commons-codec 1.15, but the project gets 1.11: both requests are equally far from the project, and the one from the dependency declared first wins. [How Maven resolves dependencies](how-dependencies-work.html#Nearest_wins) explains the rule. A line in brackets is a dependency that Maven left out, with the reason:

| Remark | Meaning |
|---|---|
| `omitted for conflict with 1.11` | Another version of the same library won. |
| `omitted for duplicate` | The same version is already in the tree at another place. |
| `version managed from 1.15` | `<dependencyManagement>` set the version; 1.15 is what the dependency's POM asked for. |
| `scope not updated to compile` | The library is also a direct dependency, and the scope you declared stays. |

When a newer version lost, as here, the library that asked for it may fail at runtime. [Control the version of a transitive dependency](control-a-transitive-version.html) shows how to choose the version yourself.

## Find libraries you use but did not declare

Your code may use a library that only reaches the project through another dependency. It compiles today, and breaks when that dependency drops the library in a new release. The `analyze` goal compiles the project and compares the classes your code uses with the dependencies you declared:

```
mvn dependency:analyze
```

```
[WARNING] Used undeclared dependencies found:
[WARNING]    commons-codec:commons-codec:jar:1.11:compile
[WARNING] Unused declared dependencies found:
[WARNING]    org.apache.httpcomponents.client5:httpclient5:jar:5.1.4:compile
```

Declare each used undeclared dependency in your POM. An unused declared dependency is one your code does not reference in its compiled classes; check before you remove it, because libraries that are only loaded at runtime, such as a JDBC driver or a logging backend, are reported here too. Give those scope `runtime`.

To make the build fail on these warnings, set `failOnWarning` in the configuration of the goal; the [analyze goal reference](../../plugins/maven-dependency-plugin/analyze-mojo.html) lists it and the options to ignore single dependencies.
