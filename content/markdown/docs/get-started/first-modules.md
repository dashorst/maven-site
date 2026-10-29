---
title: Split your application into modules
summary: Turn my-app into a parent POM with a library module and an application module, build them together, and build one with what it needs.
type: tutorial
since: 3.9
keywords: multi-module, multi-project, monorepo, submodule, subproject, parent POM, aggregator, Reactor Build Order, Reactor Summary, build one module, Could not resolve dependencies, library module
terms: <modules> | <module> | <subprojects> | <parent> | pom packaging | ${project.version} | -pl | -am | reactor
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


In this tutorial you split `my-app` into two modules: `greeting`, a library with the `Greeter` class and its test, and `app`, the application that uses it and is packed into one JAR. The top directory gets a parent POM that holds what the modules share and builds them together.

Start in the `my-app` directory as you left it at the end of [Test and build your project](test-and-build.html). At the end of this tutorial it looks like this:

```
my-app
|-- .mvn
|-- pom.xml
|-- app
|   |-- pom.xml
|   `-- src/main/java/com/mycompany/app/App.java
`-- greeting
    |-- pom.xml
    `-- src
        |-- main/java/com/mycompany/app/Greeter.java
        `-- test/java/com/mycompany/app/GreeterTest.java
```

## 1. Move the code into module directories

Remove the output of earlier builds first, while *pom.xml* still describes the old project:

```shell
mvn clean
```

Then make a directory for each module, move all code into `app`, and move `Greeter` and its test on to `greeting`:

```shell
mkdir -p app greeting/src/main/java/com/mycompany/app
mv src app/
mv app/src/test greeting/src/
mv app/src/main/java/com/mycompany/app/Greeter.java greeting/src/main/java/com/mycompany/app/
```

Each module has the [standard directory layout](standard-directory-layout.html) of its own. The `.mvn` directory stays at the top: it marks the top directory of the whole project.

## 2. Turn the top POM into a parent

In *pom.xml* in the `my-app` directory, add `<packaging>pom</packaging>` after the version and a `<modules>` list after `<url>`. Remove the Commons Lang dependency and the `<plugins>` element with the Shade plugin; they move to the modules. The file now reads:

*pom.xml*

```xml
<project ...>
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.mycompany.app</groupId>
  <artifactId>my-app</artifactId>
  <version>1.0-SNAPSHOT</version>
  <packaging>pom</packaging>

  <name>my-app</name>
  <!-- FIXME change it to the project's website -->
  <url>http://www.example.com</url>

  <modules>
    <module>greeting</module>
    <module>app</module>
  </modules>

  <properties>
    ...
  </properties>

  <dependencyManagement>
    ...
  </dependencyManagement>

  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <scope>test</scope>
    </dependency>
    ...
  </dependencies>

  <build>
    <pluginManagement>
      ...
    </pluginManagement>
  </build>
</project>
```

Packaging `pom` means that this project builds no JAR of its own. `<modules>` lists the directories of the modules, and makes Maven build them whenever you build this project.

This POM is also the parent of both modules. They inherit its `groupId` and `version`, its properties such as `maven.compiler.release`, the plugin versions in `<pluginManagement>` and the JUnit dependencies, so either module can have tests.

## 3. Write the POM of the library

Create a POM for `greeting`. It names `my-app` as its parent and adds the dependency its code needs:

*greeting/pom.xml*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>com.mycompany.app</groupId>
    <artifactId>my-app</artifactId>
    <version>1.0-SNAPSHOT</version>
  </parent>

  <artifactId>greeting</artifactId>

  <dependencies>
    <dependency>
      <groupId>org.apache.commons</groupId>
      <artifactId>commons-lang3</artifactId>
      <version>3.21.0</version>
    </dependency>
  </dependencies>
</project>
```

The module only declares its `artifactId`; the rest of its coordinates come from the parent. Maven finds the parent's POM in the directory above, where it looks first.

## 4. Write the POM of the application

Create a POM for `app`. It depends on `greeting` and gets the Shade plugin from [Add and configure your first plugin](first-plugin.html):

*app/pom.xml*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>com.mycompany.app</groupId>
    <artifactId>my-app</artifactId>
    <version>1.0-SNAPSHOT</version>
  </parent>

  <artifactId>app</artifactId>

  <dependencies>
    <dependency>
      <groupId>com.mycompany.app</groupId>
      <artifactId>greeting</artifactId>
      <version>${project.version}</version>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.6.2</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <transformers>
                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                  <mainClass>com.mycompany.app.App</mainClass>
                </transformer>
              </transformers>
              <createDependencyReducedPom>false</createDependencyReducedPom>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

A module uses another module through an ordinary dependency on its coordinates. `${project.version}` is the version of this project, so `app` always uses the `greeting` of the same version. `app` gets Commons Lang through `greeting`, without declaring it.

> **Maven 4:** With model version 4.1.0, which only Maven 4 reads, the POMs can be shorter. The parent lists `<subprojects>` with one `<subproject>` per directory instead of `<modules>`, a module names its parent with an empty `<parent/>`, and `app` can leave out the `<version>` of `greeting`:
>
> *app/pom.xml*
>
> ```xml
> <project xmlns="http://maven.apache.org/POM/4.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
>   xsi:schemaLocation="http://maven.apache.org/POM/4.1.0 https://maven.apache.org/xsd/maven-4.1.0.xsd">
>   <modelVersion>4.1.0</modelVersion>
>
>   <parent/>
>
>   <artifactId>app</artifactId>
>
>   <dependencies>
>     <dependency>
>       <groupId>com.mycompany.app</groupId>
>       <artifactId>greeting</artifactId>
>     </dependency>
>   </dependencies>
>   ...
> </project>
> ```
>
> Maven 3 stops on such a POM with `Unrecognised tag: 'subprojects'`. [Split a project into modules](../multi-module/split-into-modules.html#Use_subprojects_on_Maven_4) shows the parent POM in this form.

## 5. Build all modules

In the `my-app` directory, run:

```shell
mvn clean verify
```

Maven reads the parent POM, finds the modules, and puts all three projects in an order in which every project comes after the projects it needs. It prints that order first:

```
[INFO] Reactor Build Order:
[INFO]
[INFO] my-app                                                             [pom]
[INFO] greeting                                                           [jar]
[INFO] app                                                                [jar]
```

Then it builds them one after the other, in one run: it tests `greeting` and makes its JAR, and then compiles `app` against that JAR and packs both, with Commons Lang, into one. The summary at the end lists each project:

```
[INFO] Reactor Summary for my-app 1.0-SNAPSHOT:
[INFO]
[INFO] my-app ............................................. SUCCESS [  0.510 s]
[INFO] greeting ........................................... SUCCESS [  1.180 s]
[INFO] app ................................................ SUCCESS [  0.256 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
```

The part of Maven that builds several projects together is called the reactor. Each module has its own `target` directory. Run the application from the JAR of `app`:

```shell
java -jar app/target/app-1.0-SNAPSHOT.jar ada
```

```
Hello, Ada!
```

## 6. Build one module and what it needs

You can build part of the project from the top directory with `-pl`, short for `--projects`, followed by the module's directory. Start from nothing and try `app` alone:

```shell
mvn clean
mvn -pl app verify
```

```
[ERROR] Failed to execute goal on project app: Could not resolve dependencies for project com.mycompany.app:app:jar:1.0-SNAPSHOT
[ERROR] dependency: com.mycompany.app:greeting:jar:1.0-SNAPSHOT (compile)
```

`greeting` is not part of this build, so Maven looks for it in the local repository, as for any other dependency, and you never installed it. The line after these two gives a reason that differs between Maven versions: Maven 3.10 and 4 say the path is `NOT allowed from central`, which only means that Maven Central has no such library.

Add `-am`, short for `--also-make`, to build the module together with the modules it needs:

```shell
mvn -pl app -am verify
```

```
[INFO] Reactor Summary for my-app 1.0-SNAPSHOT:
[INFO]
[INFO] my-app ............................................. SUCCESS [  0.001 s]
[INFO] greeting ........................................... SUCCESS [  1.695 s]
[INFO] app ................................................ SUCCESS [  0.273 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
```

Maven builds `greeting` because `app` depends on it, and the parent `my-app` because `app` inherits from it. Here that is the whole project; in a larger project, `-am` leaves out the modules that `app` does not need. [Build part of a multi-module project](../multi-module/build-part-of-a-project.html) shows the other ways to select modules.

> **Maven 4:** When Maven 4 packages a module, it keeps a copy of the JAR in `.mvn/target/project-local-repo`. After a full `mvn verify`, `mvn -pl app verify` finds `greeting` there and succeeds; `mvn clean` removes the copies, so the build above fails on Maven 4 as well.

You now have a project of two modules that build together with one command, and you can build one of them with what it needs.

## Where to go from here

[Aggregation and inheritance](../multi-module/aggregation-and-inheritance.html) explains the two roles the parent POM plays, and [Split a project into modules](../multi-module/split-into-modules.html) is the same work as a checklist for your own projects. The rest of the Docs section is grouped by subject: Dependencies and repositories, Multi-module projects, Java versions and toolchains, Plugins, extensions and tools, and Build recipes, each starting from what you did in these five tutorials.
