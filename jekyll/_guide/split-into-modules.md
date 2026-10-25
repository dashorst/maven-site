---
title: Split a project into modules
type: howto
topic: multi-module
summary: Turn one Maven project into a parent POM with modules that depend on each other and build together from the root directory.
since: "3.9"
terms: [<modules>, <module>, <subprojects>, <parent>, pom packaging, "${project.version}", .mvn]
keywords: [multi-module, multi-project, monorepo, submodule, subproject, parent POM, aggregator, reactor, split jar, restructure project]
order: 10
source: [guides/mini/guide-multiple-modules.md, guides/mini/guide-multiple-subprojects-4.md, guides/introduction/introduction-to-the-pom.md]
---

Split a project into modules when parts of it should be built, tested or released as separate jars but still be built together. The steps below turn a project `shop` into three modules: `api` with interfaces, `core` that implements them, and `app` that uses `core`. The root POM becomes both the parent the modules inherit from and the aggregator that lists them; [Aggregation and inheritance](aggregation-and-inheritance.html) explains the two roles.

The result has this layout:

```
shop/
├── pom.xml
├── api/
│   ├── pom.xml
│   └── src/main/java/...
├── core/
│   ├── pom.xml
│   └── src/main/java/...
└── app/
    ├── pom.xml
    └── src/main/java/...
```

## Turn the root POM into a parent

Change the packaging of the root POM to `pom`, so that it builds no jar of its own, and list the module directories under `<modules>`. Keep the `groupId`, `version` and properties: the modules inherit them.

*pom.xml*

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example.shop</groupId>
  <artifactId>shop</artifactId>
  <version>1.0-SNAPSHOT</version>
  <packaging>pom</packaging>

  <modules>
    <module>api</module>
    <module>core</module>
    <module>app</module>
  </modules>

  <properties>
    <maven.compiler.release>17</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>
</project>
```

Move the project's `<dependencies>` out of the root POM into the modules that use them. Dependencies left in the parent are added to every module. To keep their versions in one place, see [Share dependency versions and plugin configuration](share-configuration.html).

## Create a POM for each module

Each module gets a directory with the name you listed and a POM that names the root POM as its parent. The module inherits `groupId` and `version`, so it only declares its `artifactId`.

*api/pom.xml*

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>com.example.shop</groupId>
    <artifactId>shop</artifactId>
    <version>1.0-SNAPSHOT</version>
  </parent>

  <artifactId>api</artifactId>
</project>
```

The parent's POM is one directory up, where Maven looks first, so the `<parent>` needs no `<relativePath>`.

## Move the code into the modules

Every module has the [standard directory layout](standard-directory-layout.html) of its own. Move the existing `src` directory into the module that gets most of the code, then move the other packages to the other modules. With Git, `git mv` keeps the history of the files. In the root directory:

```
mkdir core
git mv src core/src
```

The root directory now holds no sources, only the POM and the module directories.

## Make one module depend on another

A module uses another module through an ordinary dependency. Use `${project.version}` as the version, so that the modules always use each other's current version.

*app/pom.xml*

```xml
<parent>
  <groupId>com.example.shop</groupId>
  <artifactId>shop</artifactId>
  <version>1.0-SNAPSHOT</version>
</parent>

<artifactId>app</artifactId>

<dependencies>
  <dependency>
    <groupId>com.example.shop</groupId>
    <artifactId>core</artifactId>
    <version>${project.version}</version>
  </dependency>
</dependencies>
```

`core` depends on `api` in the same way. A module only sees the classes of the modules it depends on, directly or through another module.

## Build from the root directory

Run Maven in the root directory:

```
mvn verify
```

Maven builds the parent and the modules in one run, in an order where every module comes after the modules it depends on. The summary at the end lists them in that order:

```
[INFO] Reactor Summary for shop 1.0-SNAPSHOT:
[INFO] 
[INFO] shop ............................................... SUCCESS [  0.106 s]
[INFO] api ................................................ SUCCESS [  0.908 s]
[INFO] core ............................................... SUCCESS [  0.083 s]
[INFO] app ................................................ SUCCESS [  0.063 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
```

Each module's jar is in its own `target` directory, such as `app/target/app-1.0-SNAPSHOT.jar`. Within this build, `app` uses the `core` built earlier in the same run; nothing has to be installed. To build only some of the modules, see [Build part of a multi-module project](build-part-of-a-project.html).

## Mark the root directory

Create an empty `.mvn` directory next to the root POM. Maven 3 accepts it, and Maven 4 uses it to find the root of the project; without it Maven 4 may warn `Unable to find the root directory`. Git does not store empty directories, so add a file to it, for example an empty [`maven.config`](configuration-files.html). Maven 4 writes build output to `.mvn/target`, so add that directory to your `.gitignore`.

```
mkdir .mvn
```

## Use subprojects on Maven 4

> **Maven 4:** With model version 4.1.0 the root POM lists `<subprojects>` instead of `<modules>`, or lists nothing at all: a `pom`-packaged 4.1.0 POM without either element builds every direct subdirectory that has a `pom.xml`. A subproject can name its parent with an empty `<parent/>`, which means the POM one directory up, and can depend on another subproject without a version. Maven 3 cannot read these POMs; it stops with `Unrecognised tag: 'subprojects'`.
>
> *pom.xml*
>
> ```xml
> <project xmlns="http://maven.apache.org/POM/4.1.0"
>          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
>          xsi:schemaLocation="http://maven.apache.org/POM/4.1.0 https://maven.apache.org/xsd/maven-4.1.0.xsd">
>   <modelVersion>4.1.0</modelVersion>
>
>   <groupId>com.example.shop</groupId>
>   <artifactId>shop</artifactId>
>   <version>1.0-SNAPSHOT</version>
>   <packaging>pom</packaging>
>
>   <subprojects>
>     <subproject>api</subproject>
>     <subproject>core</subproject>
>     <subproject>app</subproject>
>   </subprojects>
> </project>
> ```
>
> *app/pom.xml*
>
> ```xml
> <project xmlns="http://maven.apache.org/POM/4.1.0"
>          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
>          xsi:schemaLocation="http://maven.apache.org/POM/4.1.0 https://maven.apache.org/xsd/maven-4.1.0.xsd">
>   <modelVersion>4.1.0</modelVersion>
>
>   <parent/>
>
>   <artifactId>app</artifactId>
>
>   <dependencies>
>     <dependency>
>       <groupId>com.example.shop</groupId>
>       <artifactId>core</artifactId>
>     </dependency>
>   </dependencies>
> </project>
> ```
>
> When it installs or deploys `app`, Maven 4 writes the parent's coordinates and the version of `core` into the published POM, so projects built with Maven 3 can use it.
