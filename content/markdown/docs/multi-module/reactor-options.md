---
title: Reactor options
summary: The command-line options that select, order and continue the modules of a multi-module build, the project selector syntax, and the Maven line each needs.
type: reference
since: 3.9
keywords: command line, CLI flags, project selector, exclude module, optional project, parallel build, threads, resume.properties, Could not find the selected project in the reactor, The requested required projects do not exist, Unrecognized option
terms: -pl | --projects | -am | --also-make | -amd | --also-make-dependents | -rf | --resume-from | -r | --resume | -N | --non-recursive | -f | -fae | --fail-at-end | -ff | --fail-fast | -fn | --fail-never | -T | --threads
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


These options change which modules of a multi-module build Maven builds, from where, and what happens when one fails. Without them, Maven builds the project in the current directory and all its modules. The complete list of command-line options is in the [CLI options reference](../../ref/current/maven-embedder/cli.html); `mvn --help` prints it for the Maven you run. [Build part of a multi-module project](build-part-of-a-project.html) shows the common combinations.

## Selecting modules

| Option | Long form | Effect | Maven |
|---|---|---|---|
| [`-pl`](../../ref/current/maven-embedder/cli.html) | `--projects` | Builds only the listed modules, a comma-separated list of [project selectors](#Project_selectors). Modules they need come from the local repository unless they are selected too; Maven 4 looks in `.mvn/target/project-local-repo` first. | 3.9, 3.10, 4.0 |
| [`-am`](../../ref/current/maven-embedder/cli.html) | `--also-make` | Adds the modules the selected ones depend on, directly or indirectly, and their parents. | 3.9, 3.10, 4.0 |
| [`-amd`](../../ref/current/maven-embedder/cli.html) | `--also-make-dependents` | Adds the modules that depend on the selected ones, directly or indirectly. | 3.9, 3.10, 4.0 |
| [`-rf`](../../ref/current/maven-embedder/cli.html) | `--resume-from` | Takes one project selector and leaves out every module that comes before it in the build order. | 3.9, 3.10, 4.0 |
| [`-r`](../../ref/current/maven-embedder/cli.html) | `--resume` | Builds only the modules that failed or were skipped in the previous build, as recorded in `target/resume.properties` of the root directory. | 4.0 |
| [`-N`](../../ref/current/maven-embedder/cli.html) | `--non-recursive` | Builds the POM in the current directory without its modules. With `-pl` on Maven 4: selects an aggregator without its subprojects. | 3.9, 3.10, 4.0 |
| [`-f`](../../ref/current/maven-embedder/cli.html) | `--file` | Starts from another POM file, or the `pom.xml` in another directory, as if Maven ran there. | 3.9, 3.10, 4.0 |

`-am` and `-amd` without `-pl` select nothing extra on Maven 3. On Maven 4 they apply to the project in the current directory, and reach the whole project even when you start in a subproject's directory.

Maven 3 does not know `-r` and stops with `Unrecognized option: -r`. The CLI options reference describes the latest Maven 3 release; Maven 4 lists `-r` in `mvn --help`.

## Project selectors

`-pl` takes a comma-separated list of selectors, `-rf` takes one. Each selector names one module of the build.

| Selector | Selects | Example |
|---|---|---|
| path | the module in that directory, relative to the current directory | `core`, `services/billing`, `./core` |
| `:artifactId` | the module with that artifact id | `:core` |
| `groupId:artifactId` | the module with that group and artifact id | `com.example.shop:core` |

A selector without a colon is always a path. When the directory name differs from the artifact id, the artifact id alone does not select the module: write it with a colon in front.

Prefixes go before the selector:

| Prefix | Meaning | Example | Maven |
|---|---|---|---|
| `!` or `-` | exclude the module from the build | `-pl '!app'`, `-pl -app` | 3.9, 3.10, 4.0 |
| `+` | select the module; the same as no prefix | `-pl +core` | 3.9, 3.10, 4.0 |
| `?` | do not fail when no module matches; goes after `!`, `-` or `+` | `-pl '?docs'`, `-pl '!?docs'` | 4.0 |

Quote selectors with `!` or `?` in the shell: Bash treats `!` as a history command and `?` as a wildcard.

A selector that matches no module stops the build before anything is built. Maven 3 reports `Could not find the selected project in the reactor: docs`, Maven 4 `The requested required projects docs do not exist.` Maven 3 reports `?docs` the same way, as it does not know the `?` prefix.

Selecting or excluding an aggregator differs between the lines:

| Selector on an aggregator `services` with subprojects `billing` and `shipping` | Maven 3.9, 3.10 | Maven 4.0 |
|---|---|---|
| `-pl services` | `services` | `services`, `billing`, `shipping` |
| `-pl services -N` | fails: `-N` leaves only the root project in the build | `services` |
| `-pl '!services'` | everything except `services` | everything except `services`, `billing` and `shipping` |

## Failures

| Option | Long form | When a module fails | Exit status | Maven |
|---|---|---|---|---|
| [`-ff`](../../ref/current/maven-embedder/cli.html) | `--fail-fast` | Stops; all modules after it are skipped. The default. | failure | 3.9, 3.10, 4.0 |
| [`-fae`](../../ref/current/maven-embedder/cli.html) | `--fail-at-end` | Skips only the modules that depend on the failed one and builds the rest. | failure | 3.9, 3.10, 4.0 |
| [`-fn`](../../ref/current/maven-embedder/cli.html) | `--fail-never` | Builds all other modules, including those that depend on the failed one. | success, although the log ends with `BUILD FAILURE` | 3.9, 3.10, 4.0 |

With `-fn`, a module that depends on the failed module is built against whatever version of it Maven can find, such as an older one in the local repository.

After a failure, Maven 3 prints the command to resume with, `mvn <args> -rf :core`. Maven 4 prints `mvn [args] -r`, and its `target/resume.properties` lists the failed and skipped modules. After a successful build, Maven 4 deletes that file.

## Parallel builds

| Option | Long form | Effect | Maven |
|---|---|---|---|
| [`-T`](../../ref/current/maven-embedder/cli.html) | `--threads` | Builds modules that do not depend on each other at the same time. Takes a thread count, `-T 4`, or a count per CPU core with `C`, `-T 1C`. | 3.9, 3.10, 4.0 |

The order of the modules still holds: a module starts only after the modules it depends on are finished. Maven logs `Using the MultiThreadedBuilder implementation with a thread count of 4`.
