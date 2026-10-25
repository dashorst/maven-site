---
title: Toolchains and the JDK Maven runs on
type: explanation
topic: jdk
summary: Why Maven keeps the JDK it runs on apart from the JDK that compiles and tests your code, how plugins find that JDK, and how it differs from release.
since: "3.9"
terms: [toolchains.xml, maven-toolchains-plugin, JAVA_HOME, jdkToolchain, select-jdk-toolchain, maven.compiler.release]
keywords: [JDK, javac, java version, multiple JDKs, different JDK, build JDK, runtime JDK, Java 8, Java 11, Java 17, project SDK, cross-compile, --release]
order: 10
source: [guides/mini/guide-using-toolchains.md]
---

Maven is a Java program. The `mvn` command starts it on the JDK that `JAVA_HOME` points to, or on the `java` command on your path when `JAVA_HOME` is not set. Unless you say otherwise, every plugin that needs a JDK tool takes it from that same JDK: the compiler plugin compiles with its compiler, Surefire starts the tests with its `java`, and the Javadoc plugin runs its `javadoc`. The JDK that runs Maven and the JDK that builds your code are then the same JDK.

## Two JDKs in one build

They do not have to be the same, and often should not be. Your project may have to be tested on Java 11 while you run Maven on Java 21. A team may want every build to use the JDK that production runs on, whatever each developer has as a default. A library may be compiled with the newest JDK and still have its tests run on the oldest Java it supports.

Changing `JAVA_HOME` before each build works for one project at a time, but it also changes the JDK Maven itself runs on, it has to be repeated in every shell and on every build server, and nothing in the project records which JDK it needs.

> **Maven 4:** Maven 4 does not start on a Java version older than 17. To compile and test a project with Java 8 or 11 under Maven 4, you need a toolchain. Maven 3.9 and 3.10 run on Java 8 and later.

## What a toolchain is

A toolchain is a description of a tool installed on the machine: what type of tool it is, what it provides, and where it is. For a JDK that is the type `jdk`, a version and other labels such as a vendor, and the JDK's home directory. These descriptions live outside the project, in *~/.m2/toolchains.xml* on each machine, because the paths differ from one machine to the next. The project only states what it needs: a JDK of version 17.

It is the same split as in an IDE, where you register the JDKs installed on your computer once and each project picks one of them. At the start of the build Maven matches the project's requirement against the descriptions on the machine, and the build fails when none fits, instead of quietly using another JDK.

## Why not configure each plugin

Most plugins that use a JDK can also be pointed at one directly: the compiler plugin with `fork` and `executable`, Surefire with `jvm`, the Javadoc plugin with `javadocExecutable`. That puts the path of a JDK in the POM, which is wrong on every machine but one unless you route it through a property, and it has to be repeated for every plugin. Miss one and your code is compiled with Java 17 but tested on Java 21, or the Javadoc is made by a third JDK. A toolchain is selected once, and every toolchain-aware plugin in the module uses it.

## How a plugin finds its toolchain

Selecting a toolchain and using it are the work of different plugins. The maven-toolchains-plugin runs at the start of the build, in the `validate` phase. Its `toolchain` goal compares the requirement in the POM with the toolchains in *toolchains.xml*. Its `select-jdk-toolchain` goal, available since version 3.2.0 of the plugin, also considers the JDKs it finds installed on the machine. Either goal stores the toolchain it selects in the build context of the module that is being built.

Each toolchain-aware plugin that runs later asks that build context for a toolchain of type `jdk`. When there is one, the plugin takes its tools from that JDK: the compiler plugin starts the toolchain's `javac` in a separate process, and Surefire and Failsafe start the test JVM from it. When there is none, the plugin uses the JDK Maven runs on. The build log shows both halves, first `Found matching toolchain for type jdk` from the toolchains plugin, then a line such as `Toolchain in maven-compiler-plugin` from each plugin that uses it.

Because the selection belongs to a module, a module in a multi-module build that does not run the toolchains plugin is built with Maven's own JDK. Configure the plugin in a parent POM to cover every module. A plugin that is not toolchain-aware ignores the selection altogether; [the toolchains.xml reference](toolchains-xml.html#Plugins_that_use_toolchains) lists the plugins that are.

Several plugins, among them the compiler plugin, Surefire, Failsafe and the Javadoc plugin, also accept a requirement of their own in a `jdkToolchain` parameter. It overrides the module's selection for that one plugin, which is how a build compiles with one JDK and runs its tests on another. A plugin's own requirement is looked up in *toolchains.xml* only, not among the JDKs that `select-jdk-toolchain` discovers.

## Written down or discovered

There are two ways for Maven to know about the JDKs on a machine.

In *toolchains.xml* you describe each JDK yourself. The labels in it are yours: Maven does not check that the JDK in the directory you name is the version you wrote, only that the directory exists. A requirement of `17` matches an entry with the version `17`, so the labels in the file and the requirements in your POMs have to agree. In return you decide exactly which JDK a requirement selects, on every machine.

The `select-jdk-toolchain` goal looks for JDKs where installers put them and in `JAVA_HOME` and `JAVA17_HOME`-style environment variables, and reads the real version and vendor of each one, such as `17.0.20` from Eclipse Adoptium. Nobody has to write a file per machine, but a version requirement has to be a range such as `[17,18)`, and when the JDK Maven runs on already satisfies it, that JDK is used and no toolchain is selected. [Build with a different JDK than Maven runs on](build-with-another-jdk.html) shows both.

## Toolchains and the release option

The compiler's `release` option, set with the `maven.compiler.release` property, answers a different question: which Java version the compiled classes are for. The `javac` of JDK 21 with `release` 8 writes class files that Java 8 can load, and it rejects code that uses an API Java 8 does not have. If all you need is a library or application that runs on an older Java, `release` is enough, and Maven and the compiler can stay on the newer JDK. [Compile for an older Java version](compile-for-older-java.html) shows how.

You need a toolchain when something has to run on the older Java rather than be compiled for it: tests that should catch differences in the older runtime, or tools whose output depends on the JDK. You also need one when the newer compiler no longer supports the release you target: the `javac` of JDK 21 accepts `release` 8 but not 7. Most builds that select a toolchain still set `release`, so that the class files do not depend on which JDK happened to match.
