---
title: Build part of a multi-module project
summary: Build one module, a module with the modules it needs or with the modules that use it, leave modules out, or resume a failed build.
type: howto
since: 3.9
keywords: single module, one submodule, selected projects, skip module, exclude module, restart build, continue failed build, faster build, Could not find the selected project in the reactor, Could not resolve dependencies
terms: -pl | --projects | -am | --also-make | -amd | --also-make-dependents | -rf | --resume-from | -r | --resume
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


Build part of a project when you changed one module and do not want to wait for all of them, or when a build failed halfway. You run these commands in the root directory and select modules with options; [Reactor options](reactor-options.html) lists every option and the ways to name a module. The examples use a project `shop` with the modules `api`, `core` and `app`, where `app` depends on `core` and `core` on `api`.

## Build one module

Select the module with `-pl`, followed by its directory:

```
mvn verify -pl core
```

Maven builds `core` and nothing else. The modules `core` depends on are not part of this build, so Maven takes them from the local repository, like any other dependency. If you have never installed them, the build stops:

```
[ERROR] Failed to execute goal on project core: Could not resolve dependencies for project com.example.shop:core:jar:1.0-SNAPSHOT
```

Either install the whole project once with `mvn install` in the root directory, so that `-pl` finds the other modules in the local repository, or build the modules it needs along with it, as in the next section. An installed module stays at the version you installed until you install it again.

> **Maven 4:** When Maven 4 packages a subproject, it keeps a copy of the jar in `.mvn/target/project-local-repo` in the root directory, and uses that copy when the subproject is not part of a later build. `mvn clean` removes it again. Without an install or an earlier package, `-pl core` fails on Maven 4 as well.

## Build a module with the modules it needs

Add `-am` (also make) to build the selected module together with every module it depends on, directly or indirectly:

```
mvn verify -pl app -am
```

```
[INFO] Reactor Summary for shop 1.0-SNAPSHOT:
[INFO] 
[INFO] shop ............................................... SUCCESS [  0.001 s]
[INFO] api ................................................ SUCCESS [  0.546 s]
[INFO] core ............................................... SUCCESS [  0.014 s]
[INFO] app ................................................ SUCCESS [  0.010 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
```

The parent `shop` is built too, because `app` inherits from it. None of the project's own modules has to come from the local repository, which makes this the safe way to build one module.

## Build a module with the modules that use it

Add `-amd` (also make dependents) after changing a module, to check that the modules depending on it still compile and pass their tests:

```
mvn verify -pl core -amd
```

```
[INFO] Reactor Summary for core 1.0-SNAPSHOT:
[INFO] 
[INFO] core ............................................... SUCCESS [  0.586 s]
[INFO] app ................................................ SUCCESS [  0.017 s]
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
```

`-amd` does not add the modules `core` needs, so `api` still comes from the local repository. Use both options, `-pl core -am -amd`, to build `core`, what it needs and what uses it.

## Build several modules or leave one out

`-pl` takes a comma-separated list, `-pl api,app`. To build everything except some modules, put `!` before them:

```
mvn verify -pl '!app'
```

The quotes keep shells such as Bash from treating `!` as a history command. `-` works as well as `!`: `-pl -app`.

> **Maven 4:** Selecting a subproject that is itself an aggregator selects its subprojects too, and excluding it excludes them. Maven 3 selects or excludes only the aggregator. Add `-N` (`--non-recursive`) on Maven 4 to select the aggregator alone.

## Resume a failed build

When a module fails, Maven skips the modules after it and prints where to pick up again:

```
[ERROR] After correcting the problems, you can resume the build with the command
[ERROR]   mvn <args> -rf :core
```

Fix the problem and run the same command with `-rf` (resume from). Maven skips the modules that came before `core` in the build order:

```
mvn verify -rf :core
```

The modules before it are not rebuilt, so `core` takes them from the local repository, as with `-pl`.

> **Maven 4:** Maven 4 suggests `mvn [args] -r` instead. With `-r` (`--resume`), Maven reads the modules that failed or were skipped from `target/resume.properties` in the root directory, and builds only those. After `-fae`, that is the failed modules and their dependents, not everything that came after the first failure. Add `-am` to build the modules they need as well: `mvn verify -r -am`. Maven 3 does not know `-r` and stops with `Unrecognized option: -r`.

## Build from a module's directory

Running Maven in a module's directory builds that module alone, like `-pl`, and needs the other modules installed:

```
cd app
mvn verify
```

> **Maven 4:** Maven 4 knows the whole project when you start in a subproject's directory. `mvn verify -am` in `app` builds `shop`, `api`, `core` and `app`, and `mvn verify -amd` in `api` builds `api`, `core` and `app`. Maven 3 ignores the rest of the project and builds only the module in the current directory.
