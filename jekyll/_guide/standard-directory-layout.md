---
title: Standard directory layout
type: reference
topic: start
summary: The directories and files of a Maven project, what goes in each, and which plugin reads or writes it.
since: "3.9"
terms: [src/main/java, src/main/resources, src/test/java, src/test/resources, src/main/webapp, src/site, src/it, target, .mvn, .mvn/maven.config, .mvn/jvm.config, .mvn/extensions.xml, <sourceDirectory>]
keywords: [project structure, folder structure, convention over configuration, source folder, resources folder, build output, target/classes, test-classes, surefire-reports, project root]
order: 10
source: [guides/introduction/introduction-to-the-standard-directory-layout.md]
---

Maven expects the files of a project in fixed places, so a project only has to describe what is different about it, and anyone who knows one Maven project finds their way in another. The paths below are relative to the directory that holds *pom.xml*.

## Top-level files and directories

| Path | Contents | Used by |
|---|---|---|
| `pom.xml` | The project's POM. | Maven |
| `src/` | Everything the build is made from: code, resources, documentation. | Plugins, see below |
| `target/` | Everything the build produces. `mvn clean` deletes it. | Plugins, see below |
| `.mvn/` | Maven configuration for this project. Its location marks the root directory of the project, or of a multi-module build. | Maven |
| `.mvn/maven.config` | Command-line options added to every `mvn` run in the project, one option per line. | Maven |
| `.mvn/jvm.config` | Options for the JVM that Maven runs in, such as `-Xmx2g`. | Maven |
| `.mvn/extensions.xml` | Core extensions to load before the build. See [Using extensions](../guides/mini/guide-using-extensions.html). | Maven |
| `LICENSE`, `NOTICE`, `README` | Documents for people who receive the source, in any text format. | Not read by Maven |

The only other directories at the top are those of the version control system, such as `.git`, and subprojects in a [multi-module build](aggregation-and-inheritance.html), each laid out the same way.

> **Maven 4:** Without a `.mvn` directory, Maven 4 warns `Unable to find the root directory. Create a .mvn directory in the root directory or add the root="true" attribute on the root project's model to identify it.`

## Source directories

Under `src`, `main` holds what goes into the artifact and `test` what is needed only to test it. Within each, there is one directory per kind of input.

| Path | Contents | Used by |
|---|---|---|
| `src/main/java` | Java source code, in directories by package. | `compiler:compile`, into `target/classes` |
| `src/main/resources` | Files that go on the classpath next to the classes, such as property files. They end up in the JAR. | `resources:resources`, into `target/classes` |
| `src/main/filters` | Property files with values for [resource filtering](../guides/getting-started/index.html#How_do_I_filter_resource_files.3F). | Only when you name them in `<build><filters>` |
| `src/main/webapp` | The web application: `WEB-INF/web.xml`, pages, static files. | `war:war`, for packaging `war` |
| `src/main/<language>` | Sources in another language or format, such as grammars or models. | The plugin for that language |
| `src/test/java` | Test source code. | `compiler:testCompile` into `target/test-classes`, and `surefire:test` |
| `src/test/resources` | Files on the classpath of the tests only. | `resources:testResources`, into `target/test-classes` |
| `src/test/filters` | Property files for filtering the test resources. | Only when you name them in `<build><filters>` |
| `src/it` | Integration tests, mostly of Maven plugins: one small Maven project per test. | `maven-invoker-plugin` |
| `src/assembly` | Descriptors for the Assembly plugin. | Only when you name them in the plugin's configuration |
| `src/site` | Pages and configuration of the project website. | `site:site` |

## Build output

| Path | Contents | Written by |
|---|---|---|
| `target/classes` | Compiled classes and processed resources. | `compiler:compile`, `resources:resources` |
| `target/test-classes` | Compiled tests and processed test resources. | `compiler:testCompile`, `resources:testResources` |
| `target/generated-sources` | Source code generated during the build, such as by annotation processors. | `compiler:compile` and code generators |
| `target/generated-test-sources` | Test source code generated during the build. | `compiler:testCompile` and code generators |
| `target/surefire-reports` | Test results, as text and XML. | `surefire:test` |
| `target/<artifactId>-<version>.jar` | The packaged artifact; `.war` for packaging `war`. | `jar:jar`, `war:war` |
| `target/maven-archiver` | `pom.properties`, with the coordinates written into the JAR. | `jar:jar` |
| `target/maven-status` | State the Compiler plugin keeps to compile only what changed. | `compiler:compile`, `compiler:testCompile` |
| `target/site` | The generated website. | `site:site` |
| `target/dependency` | Copies of the project's dependencies. | `dependency:copy-dependencies` |

## Changing a directory

The defaults are set in the [Super POM](https://maven.apache.org/ref/current/maven-model-builder/super-pom.html), which every POM inherits. A project can override them in `<build>`, for example to compile sources from `src/java`:

*pom.xml*

```xml
<build>
  <sourceDirectory>src/java</sourceDirectory>
</build>
```

The other elements are `<testSourceDirectory>`, `<resources>`, `<testResources>`, `<directory>` for `target`, `<outputDirectory>` and `<testOutputDirectory>`; see `<build>` in the [POM reference](../pom.html#The_Build_Element_Set).
