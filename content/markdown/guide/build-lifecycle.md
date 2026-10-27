---
title: Phases, goals and plugins
summary: How Maven turns a command such as mvn package into a series of plugin goals, and why every Maven project builds with the same few commands.
type: explanation
since: 3.9
keywords: build lifecycle, default lifecycle, clean lifecycle, site lifecycle, mojo, plugin binding, default bindings, execution order, before:, after:, why does package run tests, Version not locked for default bindings plugins
terms: mvn package | mvn verify | mvn install | mvn clean | <packaging> | <executions> | <phase> | <goal> | <pluginManagement> | integration-test | pre-integration-test | post-integration-test
---


Every Maven project builds with the same commands. `mvn package` makes a JAR of a library and a WAR of a web application; `mvn verify` builds and checks either one. The person who runs the build says how far the build should go. The project decides what happens on the way there. Three ideas make that split work: the lifecycle, its phases, and the plugin goals bound to those phases.

## A lifecycle is a fixed list of phases

Maven has three lifecycles. The default lifecycle builds, tests and ships the project. The clean lifecycle removes what an earlier build produced. The site lifecycle generates the project's website.

Each lifecycle is a list of phases in a fixed order. The phases of the default lifecycle that you call from the command line are:

| Phase | What happens |
|---|---|
| `validate` | Check that the project is complete and correct. |
| `compile` | Compile the source code. |
| `test` | Run the unit tests against the compiled code. |
| `package` | Package the compiled code, for example into a JAR file. |
| `verify` | Run integration tests and other checks on the package. |
| `install` | Copy the package into the local repository, for other projects on your machine. |
| `deploy` | Copy the package to a remote repository, for other people. |

Between these are phases such as `generate-sources`, `process-resources`, `test-compile` and `prepare-package`. The [lifecycles reference](https://maven.apache.org/ref/current/maven-core/lifecycles.html) lists every phase of the three lifecycles.

When you name a phase, Maven runs all phases before it in the same lifecycle first. That is why `mvn package` runs the tests: `test` comes before `package`, and a JAR is only made from code that passed its tests. It is also why one command is enough. `mvn install` compiles, tests, packages and verifies before it installs, so there is no need to call each step.

You can name phases of different lifecycles in one command. `mvn clean package` runs the clean lifecycle up to `clean`, and then the default lifecycle up to `package`.

## Plugin goals do the work

A phase is a name for a step. It does nothing by itself. The work is done by plugins: each plugin is a Java library with one or more goals, and each goal is one task. The Compiler plugin has a `compile` goal for your code and a `testCompile` goal for your tests. When a goal is bound to a phase, it runs every time the build passes that phase. A phase with no goal bound to it is skipped without notice.

The build output names each goal it runs:

```
[INFO] --- compiler:3.13.0:compile (default-compile) @ my-app ---
```

This line reads as: the `compile` goal of the plugin with prefix `compiler`, version 3.13.0, in the execution `default-compile`, for the project `my-app`.

You can also run a goal on its own, with `prefix:goal` on the command line. `mvn dependency:tree` runs only the `tree` goal of the Dependency plugin, and no phases. Goals and phases mix: `mvn clean dependency:copy-dependencies package` cleans, then copies the dependencies, then runs the default lifecycle up to `package`, in that order.

Options that seem to change the lifecycle usually belong to a goal. `-DskipTests` does not leave out the `test` phase; it tells the Surefire plugin's `test` goal to run no tests, and the goal logs `Tests are skipped.`

## The packaging decides the default goals

Which goals a phase runs depends first of all on the project's packaging, the `<packaging>` element of the POM. A project without one has packaging `jar`, and gets these goals:

| Phase | Goal |
|---|---|
| `process-resources` | `resources:resources` |
| `compile` | `compiler:compile` |
| `process-test-resources` | `resources:testResources` |
| `test-compile` | `compiler:testCompile` |
| `test` | `surefire:test` |
| `package` | `jar:jar` |
| `install` | `install:install` |
| `deploy` | `deploy:deploy` |

Packaging `war` binds the same goals, with `war:war` instead of `jar:jar`. Packaging `pom`, used for parent projects that only hold configuration, binds nothing but `install:install` and `deploy:deploy`, because there is nothing to compile. The [plugin bindings reference](https://maven.apache.org/ref/current/maven-core/default-bindings.html) lists the bindings for every packaging.

So `mvn package` means "compile, test and make a JAR" in one project and "compile, test and make a WAR" in another, and you do not need to know which before you run it.

## Plugins in the POM add goals

To add a step to the build, you add a plugin to the `<build>` section of the POM, with an execution that names the goal. This makes the build also package the source code:

*pom.xml*

```xml
<build>
  <plugins>
    <plugin>
      <artifactId>maven-source-plugin</artifactId>
      <version>3.4.0</version>
      <executions>
        <execution>
          <goals>
            <goal>jar-no-fork</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

A goal declares the phase it belongs to by default. `jar-no-fork` belongs to `package`, so `mvn package` now writes `my-app-1.0-SNAPSHOT-sources.jar` next to the JAR. When several goals are bound to the same phase, the goals of the packaging run first, then the goals from the POM in the order they appear there; here, `jar:jar` runs before `source:jar-no-fork`.

To bind a goal to another phase, name the phase in the execution with `<phase>verify</phase>`. A plugin can have several executions, each with its own goals, phase and configuration; [Configuring plugins](../guides/mini/guide-configuring-plugins.html) describes them.

## Plugin versions belong in the POM

The goals in the default bindings come from plugins whose version you did not choose. When the POM does not set one, Maven uses a default that belongs to the Maven release: Maven 3.9.16 builds a JAR with maven-jar-plugin 3.5.0, Maven 3.10.0 with 3.5.1. The same project can then build differently on two machines.

That is why the project from the quickstart archetype lists every plugin of the default bindings, with a version, in `<build><pluginManagement>`. Setting the versions there fixes them for every build of the project, whichever Maven runs it.

> **Maven 4:** Maven 4 warns when a plugin of the default bindings has no version in the POM: `Version not locked for default bindings plugins [maven-resources-plugin, maven-compiler-plugin, ...], you should define versions in pluginManagement section of your pom.xml or parent`.

## Call verify, not integration-test

The phases whose names start with `pre-`, `post-` or `process-` prepare or finish the work of the phase next to them. They produce intermediate results, and you do not normally call them.

Integration tests show why. A plugin that starts a server for the tests binds a goal to `pre-integration-test`, the tests run in `integration-test`, and the server is stopped in `post-integration-test`. Reports are checked in `verify`. In Maven 3, `mvn integration-test` stops after the `integration-test` phase: the server keeps running and no report is checked. `mvn verify` runs the whole sequence, which is why it is the command to call when you want to know whether the project builds and works.

> **Maven 4:** The default lifecycle is a tree of phases, each with a `before:` and an `after:` step, such as `before:compile` and `after:compile`. The Maven 3 names remain as aliases: `prepare-package` is `before:package`, `process-classes` is `after:compile`, `pre-integration-test` and `post-integration-test` are `before:integration-test` and `after:integration-test`. When you call a phase, Maven 4 runs its `after:` step as well. `mvn integration-test` therefore also runs `post-integration-test`, `mvn compile` also runs `process-classes`, and `mvn prepare-package` runs up to and including `package`. Maven 4 also adds phases such as `sources`, `resources` and `ready` (compiled and ready to use). The [Maven 4 lifecycles reference](https://maven.apache.org/ref/4-LATEST/impl/maven-core/lifecycles.html) lists them.
