---
title: Aggregation and inheritance
summary: How a parent POM passes configuration down, how an aggregator builds modules together, and how the reactor decides the order.
type: explanation
since: 3.9
keywords: multi-project, monorepo, submodule, subproject, parent POM, child POM, super POM, build order, consumer POM, build POM, cyclic reference, Non-resolvable parent POM, Unable to find the root directory, Gradle settings include
terms: <parent> | <relativePath> | <modules> | <module> | <subprojects> | pom packaging | reactor | effective POM | help:effective-pom | .mvn
---


A multi-module project rests on two separate relationships between POMs. Inheritance lets one POM take its configuration from another: the child names its parent. Aggregation lets one POM build other projects along with itself: the aggregator names its modules. In most projects one POM at the top does both, which is why the two are easy to mix up. They point in opposite directions, though, and each works without the other.

## Inheritance: a child names its parent

A POM with a `<parent>` element starts from the parent's configuration and adds its own on top. The parent is a POM like any other, with `pom` packaging, because it produces no jar of its own.

*core/pom.xml*

```xml
<parent>
  <groupId>com.example.shop</groupId>
  <artifactId>shop</artifactId>
  <version>1.0-SNAPSHOT</version>
</parent>

<artifactId>core</artifactId>
```

The child inherits the `groupId` and `version`, so it only needs an `artifactId`. It also inherits properties, `<dependencies>`, `<dependencyManagement>`, the build configuration with its plugins and `<pluginManagement>`, repositories, and descriptive elements such as `<description>`, `<url>`, `<licenses>`, `<developers>` and `<scm>`. Lists are merged: the child's dependencies are added to the parent's, and a plugin execution with the same id as one in the parent is merged with it. For plugin configuration you can change how the merge works with `combine.children` and `combine.self`, described in the [POM reference](../reference/pom.html#Advanced_configuration_inheritance.3A_combine.children_and_combine.self).

Some elements belong to one project only and are not inherited:

- `artifactId` and `name`
- `packaging`: a child of a `pom` parent is a `jar` unless it says otherwise
- `<modules>`: a child does not build its parent's modules
- `<profiles>`: the profiles themselves stay in the parent, but what an active parent profile sets, such as a property, does reach the child

URLs, including those in `<scm>`, are inherited with the child's `artifactId` appended: a parent with `<url>https://example.com/shop</url>` gives `core` the URL `https://example.com/shop/core`.

Inheritance is recursive. A parent can have a parent of its own, and at the top of every chain sits the [Super POM](../../ref/current/maven-model-builder/super-pom.html), built into Maven, which supplies Maven Central as repository and the default directory layout. The result of merging the whole chain is the effective POM, the configuration Maven really builds with. To see it for one module, run this in the root directory:

```
mvn help:effective-pom -pl core
```

## Where Maven finds the parent

Maven looks for the parent in three places, in this order:

1. The POM at `<relativePath>`, which defaults to `../pom.xml`. Maven uses it only if its coordinates match those in `<parent>`.
2. The local repository.
3. The remote repositories.

So a parent one directory up needs no `<relativePath>`. A parent elsewhere needs one, or Maven passes over it and looks in the repositories:

*lib/pom.xml*

```xml
<parent>
  <groupId>com.example</groupId>
  <artifactId>parent</artifactId>
  <version>1.0-SNAPSHOT</version>
  <relativePath>../parent/pom.xml</relativePath>
</parent>
```

Without it, Maven finds another POM at `../pom.xml`, or none, and when the parent was never installed the build fails with `Non-resolvable parent POM`. An empty `<relativePath/>` tells Maven to skip the file system and take the parent from a repository, which is what you want for a parent from outside the project, such as an organisation-wide parent POM.

> **Maven 4:** Maven 4 also finds the parent among the projects of the current build, so a parent that is part of the build is found even when `<relativePath>` does not point at it. And it can fill in the parent for you: an empty `<parent/>` means the POM in the directory above, and Maven reads the group id, artifact id and version from that file.

## Aggregation: an aggregator names its modules

An aggregator is a POM with `pom` packaging and a list of modules. Each `<module>` is the path from the aggregator's directory to a module's directory or POM file, usually the directory name.

*pom.xml*

```xml
<packaging>pom</packaging>

<modules>
  <module>api</module>
  <module>core</module>
  <module>app</module>
</modules>
```

When you run Maven on the aggregator, it runs the same command on every module in one build. That is all aggregation does. The aggregator passes no configuration to its modules, and a module does not know which aggregator lists it.

> **Maven 4:** The element is called `<subprojects>`, with one `<subproject>` per directory, in POMs with model version 4.1.0. `<modules>` still works there, but Maven reports it as a deprecated element and suggests `<subprojects>`. When a 4.1.0 POM with `pom` packaging lists neither, Maven 4 takes every direct subdirectory that has a `pom.xml` as a subproject.

## One POM or two

Usually the root POM is both: the modules name it as their parent, and it lists them as modules. One file then holds the shared configuration and the list of what to build, and `mvn verify` in the root directory builds everything.

The two roles can be split. A project can keep its shared configuration in `parent/pom.xml`, inherited by every module through `<relativePath>../parent/pom.xml</relativePath>`, and have a root POM that only lists `parent`, `lib` and `app` as modules. That root is then an aggregator that nothing inherits from. The other way round is common as well: a company parent POM, inherited by hundreds of projects that are each built on their own, aggregates none of them.

## The reactor orders the build

The part of Maven that builds several projects together is called the reactor. It collects the projects from the aggregator and its modules, recursively, sorts them so that every project comes after the projects it needs, and then builds them one by one. A project comes after:

- the modules it has as a dependency,
- its parent, when the parent is part of the build,
- modules it uses as a plugin, as a plugin's dependency or as a build extension.

Only those relationships count. An entry in `<dependencyManagement>` or `<pluginManagement>` that names another module does not change the order. Where no relationship decides, the order of the `<modules>` list does. So the order in which you list modules does not matter for correctness: with the modules listed as `app`, `core`, `api`, where `app` depends on `core` and `core` on `api`, the reactor still prints:

```
[INFO] Reactor Build Order:
[INFO] 
[INFO] shop                                                               [pom]
[INFO] api                                                                [jar]
[INFO] core                                                               [jar]
[INFO] app                                                                [jar]
```

The parent comes first because every module inherits from it. An aggregator that is not also the parent has no relationship with its modules, and the reactor may build it last.

Two modules that need each other, directly or through others, cannot be ordered. Maven stops before building with `The projects in the reactor contain a cyclic reference` and names the chain.

## Modules see each other's output

Within one build, a module that depends on another module gets that module's output from the build itself: its compiled classes, or its jar once it is packaged. Nothing has to be installed first. That only holds for the modules in the build. When you build one module on its own, Maven 3 looks for the other modules in the local repository, as it would for any dependency, and fails when they were never installed. [Build part of a multi-module project](build-part-of-a-project.html) shows how to select modules so that what they need is in the build.

> **Maven 4:** When Maven 4 packages a subproject, it keeps a copy of the jar in `.mvn/target/project-local-repo` in the root directory. A later build that leaves that subproject out takes the jar from there before it looks in the local repository. `mvn clean` removes the copy.

## The root directory and the POM that is published

> **Maven 4:** Maven 4 needs to know the root directory of the project. It takes the nearest directory upwards with a `.mvn` subdirectory, or the directory of a POM with `root="true"` on its `<project>` element (model version 4.1.0). When it finds neither, it warns `Unable to find the root directory. Create a .mvn directory in the root directory or add the root="true" attribute on the root project's model to identify it.` Maven 3 accepts an empty `.mvn` directory as well.

> **Maven 4:** The POM in your source tree is the build POM. Maven 4 installs and deploys a second POM next to it, the consumer POM, as the `.pom` file other projects read. It uses model version 4.0.0, so Maven 3 and other tools can read it, with versions that Maven 4 inferred filled in and without `<modules>` or `<subprojects>`. By default it keeps the `<parent>` reference. The build POM is installed and deployed too, with the classifier `build`, for example `app-1.0-SNAPSHOT-build.pom`. See [What's new in Maven 4](../maven-4/whats-new.html#Consumer_POM).
