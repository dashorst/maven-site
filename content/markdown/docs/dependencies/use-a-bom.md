---
title: Use a BOM, and publish one
summary: Import a bill of materials to get matching versions of a library family, override one of its versions, and publish a BOM for your own library.
type: howto
since: 3.9
keywords: bill of materials, platform, version alignment, jackson-bom, junit-bom, spring-boot-dependencies, import scope, managed versions, library family, bom packaging
terms: BOM | <scope>import</scope> | <type>pom</type> | <dependencyManagement> | <packaging>bom</packaging>
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

Use this when you use several artifacts of one library family, such as Jackson or JUnit, and want versions that belong together without writing each one. Many such families publish a bill of materials (BOM): a POM that contains only a `<dependencyManagement>` section with the versions of all their artifacts.

## Import a BOM

Add the BOM to the `<dependencyManagement>` section of your POM, with type `pom` and scope `import`. Then declare the artifacts you use without a version:

*pom.xml*

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>com.fasterxml.jackson</groupId>
      <artifactId>jackson-bom</artifactId>
      <version>2.22.4</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>

<dependencies>
  <dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
  </dependency>
  <dependency>
    <groupId>com.fasterxml.jackson.datatype</groupId>
    <artifactId>jackson-datatype-jsr310</artifactId>
  </dependency>
</dependencies>
```

Maven copies the managed versions of the BOM into your `<dependencyManagement>`, as if you had written them there. They apply to the artifacts you declare and to the same artifacts where they arrive transitively:

```
mvn dependency:tree
```

```
[INFO] com.example:app:jar:1.0-SNAPSHOT
[INFO] +- com.fasterxml.jackson.core:jackson-databind:jar:2.22.4:compile
[INFO] |  +- com.fasterxml.jackson.core:jackson-annotations:jar:2.22:compile
[INFO] |  \- com.fasterxml.jackson.core:jackson-core:jar:2.22.4:compile
[INFO] \- com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.22.4:compile
```

The import only works in `<dependencyManagement>`. To upgrade the whole family, change the version of the BOM. In a multi-module project, import it in the parent POM; see [Share dependency versions and plugin configuration](../multi-module/share-configuration.html#Import_a_BOM).

## Override one version of the BOM

A version you write in `<dependencyManagement>` yourself wins over the version from a BOM, before or after the import:

*pom.xml*

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>com.fasterxml.jackson</groupId>
      <artifactId>jackson-bom</artifactId>
      <version>2.22.3</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-databind</artifactId>
      <version>2.22.4</version>
    </dependency>
  </dependencies>
</dependencyManagement>
```

Only that artifact changes. The others keep the BOM's version, also where the overridden artifact asks for a newer one:

```
[INFO] com.example:app:jar:1.0-SNAPSHOT
[INFO] \- com.fasterxml.jackson.core:jackson-databind:jar:2.22.4:compile
[INFO]    +- com.fasterxml.jackson.core:jackson-annotations:jar:2.22:compile
[INFO]    \- com.fasterxml.jackson.core:jackson-core:jar:2.22.3:compile
```

`jackson-databind` 2.22.4 asks for `jackson-core` 2.22.4 and gets 2.22.3. When it needs the newer version, upgrade the BOM instead.

## Import several BOMs

You can import any number of BOMs. When two of them manage the same artifact, the BOM you import first decides its version. Put the BOM whose versions should win first, or settle the artifact with a version of your own as above.

## Publish a BOM for your library

If your library consists of several artifacts, publish a BOM so that users can import one version for all of them. Make the BOM a module of its own, next to the library's modules, that lists every artifact you publish:

*bom/pom.xml*

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.example.mylib</groupId>
  <artifactId>mylib-bom</artifactId>
  <version>1.0.0</version>
  <packaging>pom</packaging>

  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>com.example.mylib</groupId>
        <artifactId>mylib-core</artifactId>
        <version>${project.version}</version>
      </dependency>
      <dependency>
        <groupId>com.example.mylib</groupId>
        <artifactId>mylib-postgresql</artifactId>
        <version>${project.version}</version>
      </dependency>
    </dependencies>
  </dependencyManagement>
</project>
```

Do not give the BOM your project's parent POM as its parent. An import takes everything the BOM manages, including what it inherits: if the parent manages the versions of the libraries your project uses, a user who imports the BOM gets those versions too, and they can downgrade the user's own dependencies. A BOM without a parent, or with a parent that manages nothing, publishes only its own list. Make it a module of the same build, so that the [Release plugin](../recipes/release-your-project.html) gives it the version of the library.

> **Maven 4:** With model version 4.1.0, give the BOM `<packaging>bom</packaging>`. It can then keep your project's parent: Maven publishes it as a plain `pom` without the parent and with only the BOM's own managed dependencies, so Maven 3 users can import it as well. Maven 4 warns when a module imports a BOM from the same build (`BOM imports from within reactor should be avoided`); import a BOM that is published before the build instead.
