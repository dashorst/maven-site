---
title: Dependency scopes
summary: Which classpaths each scope puts a dependency on, which scopes reach the projects that depend on yours, and the scopes Maven 4 adds.
type: reference
since: 3.9
keywords: classpath, compile classpath, test classpath, runtime classpath, transitive scope, not transitive, servlet api, junit, jdbc driver, compile only, WEB-INF/lib, packaged dependencies
terms: <scope> | compile | provided | runtime | test | system | import | <systemPath> | compile-only | test-only | test-runtime
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

The `<scope>` of a dependency decides two things: on which classpaths of your project the dependency is, and whether projects that depend on yours get it too. A dependency without `<scope>` has scope `compile`.

*pom.xml*

```xml
<dependency>
  <groupId>jakarta.servlet</groupId>
  <artifactId>jakarta.servlet-api</artifactId>
  <version>6.1.0</version>
  <scope>provided</scope>
</dependency>
```

## Classpaths

A build uses three classpaths. The compiler uses the main classpath for `src/main/java`; the test classpath is used to compile and run the tests; the runtime classpath is what the code needs when it runs, and what the WAR plugin puts in `WEB-INF/lib`.

| Scope | Main classpath | Test classpath | Runtime classpath | Passed on to projects that depend on yours |
|---|---|---|---|---|
| `compile` | yes | yes | yes | yes |
| `provided` | yes | yes | no | no |
| `runtime` | no | yes | yes | yes |
| `test` | no | yes | no | no |
| `system` | yes | yes | no | yes, as `system` |

## Scopes of transitive dependencies

A dependency that your dependency brings in gets a scope in your project that depends on both scopes: the scope you gave your dependency (rows), and the scope your dependency's POM gives the library (columns).

| Your dependency's scope | `compile` | `provided` | `runtime` | `test` | optional |
|---|---|---|---|---|---|
| `compile` | `compile` | left out | `runtime` | left out | left out |
| `provided` | `provided` | left out | `provided` | left out | left out |
| `runtime` | `runtime` | left out | `runtime` | left out | left out |
| `test` | `test` | left out | `test` | left out | left out |

A library that the tree reaches through several paths gets the widest of the scopes those paths give it, unless you declare it yourself: the scope you declare always stays. [How Maven resolves dependencies](how-dependencies-work.html#Declaring_a_library_yourself_fixes_its_scope) shows what that means for a library you declare with scope `test`.

A scope in `<dependencyManagement>` also applies where the library arrives transitively, and replaces the scope the table gives it.

## compile

The default. For a library your main code uses: it is on every classpath and is passed on, so a project that depends on yours can run your code.

## provided

For a library your main code compiles against and the environment supplies at runtime, such as the Servlet API in a servlet container or an API a plugin host provides. Maven leaves it out of the runtime classpath, out of a WAR, and out of the projects that depend on yours.

## runtime

For a library your code does not reference in its source but needs to run, such as a JDBC driver or a logging backend loaded by name. Keeping it off the main classpath stops your code from coming to depend on it by accident.

## test

For a library only the tests use, such as JUnit or Mockito. It is on the test classpath only, and is never passed on.

## system

Like `provided`, but Maven does not take the file from a repository: `<systemPath>` gives the path of the JAR on the build machine.

*pom.xml*

```xml
<dependency>
  <groupId>com.example.vendor</groupId>
  <artifactId>vendor-sdk</artifactId>
  <version>4.2</version>
  <scope>system</scope>
  <systemPath>${project.basedir}/lib/vendor-sdk-4.2.jar</systemPath>
</dependency>
```

The path must be absolute; with a relative path the build stops with `must specify an absolute path`. Start it with a property such as `${project.basedir}`. Maven 3 warns that a path inside the project `will be unresolvable by dependent projects`, and Maven 3.10 warns on every use that the `system` scope is deprecated.

Unlike `provided`, a `system` dependency is passed on: a project that depends on yours gets it with scope `system` and the same path, which has to exist on that project's machine.

The path ties the build to one machine. Install the JAR in a repository instead: [Install a third-party JAR locally](third-party-jar-local.html) or [deploy it to your repository manager](third-party-jar-remote.html), and give it a normal scope. For classes of the JDK itself, which older guides declared with `system` scope and `${java.home}/lib/rt.jar`, add no dependency at all.

## import

Only in `<dependencyManagement>`, on a dependency with `<type>pom</type>`: the dependency is replaced by the managed dependencies of that POM. It does not add anything to a classpath. [Use a BOM, and publish one](use-a-bom.html) shows how it is used.

## Maven 4 scopes

With model version 4.1.0, Maven 4 accepts three more scopes, which split `provided` and `test` by classpath:

| Scope | Main classpath | Test compile classpath | Test run classpath |
|---|---|---|---|
| `compile-only` | yes | no | no |
| `test-only` | no | yes | no |
| `test-runtime` | no | no | yes |

Only plugins built on the Maven 4 API keep to these classpaths. `maven-compiler-plugin` 4.0.0-beta-5 does; `maven-compiler-plugin` 3.16.0 and `maven-surefire-plugin` 3.6.1 put a dependency with one of these scopes on every classpath they build.
