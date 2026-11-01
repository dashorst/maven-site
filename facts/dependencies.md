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

# Facts: the dependency mechanism

The claims about the dependency mechanism that the Maven documentation makes, with the Maven versions they hold for, where they are stated, and how they were checked. The pages under `content/markdown/docs/dependencies/` are written from this list. A claim marked *tested* was run on Maven 3.9.16, 3.10.0 and 4.0.0-rc-7 unless the row names fewer; *documented* means it is taken from the source without a run.

## Sources

| Id | Source |
|---|---|
| S1 | `guides/introduction/introduction-to-dependency-mechanism.md` (master, 2026-11-01) |
| S2 | `guides/introduction/introduction-to-optional-and-excludes-dependencies.md` |
| S3 | `repositories/dependency-resolution-misconceptions.md` |
| S4 | `pom.md`: Dependencies, Exclusions, Dependency Management, Dependency Version Requirement Specification |
| S5 | `whatsnewinmaven4.md`: consumer POM, model 4.1.0, bom packaging |
| S6 | `general.md` and `faq-unofficial.md`: the entries on scopes and transitive dependencies |
| S7 | `multi-module/share-configuration.md` (demo): Manage dependency versions, Import a BOM |
| S8 | Maven 4.0.0-rc-7 `maven-api-core`: `PathScope`, the dependency scopes of each path |
| S9 | Goal documentation of `maven-dependency-plugin` 3.11.0 (`tree`, `analyze`) and `maven-enforcer-plugin` 3.7.0 rules |

## Checks

Two kinds of checks. Graph checks use made-up artifacts `org.example.deps:<name>` written straight into an empty local repository, with consumer projects whose `dependency:tree` and `dependency:build-classpath` (with `includeScope` `compile`, `runtime`, `test`) are compared. The artifacts:

```
d 1.0, 1.5, 2.0, 3.0 (no dependencies)      c 1.0 -> d 2.0        b 1.0 -> c 1.0
e 1.0 -> d 1.0      f 1.0 -> d 1.0          g 1.0 -> d 2.0        rx 1.0 -> d [2.0,3.0]
s 1.0 -> tc (compile), tp (provided), tr (runtime), tt (test), to (compile, optional)
lib 1.0 -> util 1.0                         m 1.0 -> e 1.0, manages d 3.0
x1 1.0 -> b 1.0 excluding d                 k 1.0 -> b 1.0        w 1.0 -> tc 1.0
sy 1.0 -> ts 1.0 (system, absolute path)    bom-x 1.0 manages d 1.0; bom-y 1.0 manages d 2.0
```

Example checks build the projects shown on the pages against Maven Central: Apache HttpClient 4.5.14 and HttpClient 5.1.4 with Commons Codec, Guice 7.0.0 with Guava, the Jackson BOM.

## Versions and conflicts

| # | Claim | Holds for | Sources | Check |
|---|---|---|---|---|
| 1 | Of several versions of one library in the graph, the one nearest to the project wins. | 3.9, 3.10, 4.0 | S1, S4 | tested: app -> b -> c -> d 2.0 and app -> e -> d 1.0 gives d 1.0 |
| 2 | Of versions at the same depth, the first declared wins. | 3.9, 3.10, 4.0 | S1, S6 | tested: f, g gives d 1.0; g, f gives d 2.0; HttpClient 4 before 5 gives codec 1.11, after gives 1.15 |
| 3 | A version declared in the project wins over any transitive one. | 3.9, 3.10, 4.0 | S1 | tested: b, e, d 2.0 gives d 2.0 |
| 4 | A managed version replaces the version of a transitive dependency at any depth, over mediation. | 3.9, 3.10, 4.0 | S1, S4 | tested: b, e with d 3.0 managed gives d 3.0; codec 1.23.0 managed shows `version managed from 1.11` |
| 5 | A managed version does not add a dependency. | 3.9, 3.10, 4.0 | S1, S4 | tested: managed d appears only below e |
| 6 | A managed scope applies to the transitive dependency as well. | 3.9, 3.10, 4.0 | S4 | tested: d managed `provided` below b -> c becomes `provided`, off the runtime classpath |
| 7 | Managed exclusions apply where the managed dependency arrives transitively. | 3.9, 3.10, 4.0 | none | tested: k -> b -> c, c managed with d excluded: d gone |
| 8 | The `<dependencyManagement>` of a dependency's POM does not affect the project. | 3.9, 3.10 | S1 (implied) | tested: m manages d 3.0, m -> e -> d 1.0 gives d 1.0 |
| 9 | Maven 4 applies the `<dependencyManagement>` of a dependency's POM to what it brings in. | 4.0 | none | tested: same case gives d 3.0 |
| 10 | The project's own managed version wins over that of a dependency's POM. | 4.0 | none | tested: m with d 2.0 managed in the project gives d 2.0 |
| 11 | Of two imported BOMs managing one artifact, the first import wins. | 3.9, 3.10, 4.0 | S1 | tested: bom-x, bom-y gives d 1.0; bom-y, bom-x gives d 2.0 |
| 12 | A version in the project's own `<dependencyManagement>` wins over an imported BOM, before or after the import. | 3.9, 3.10, 4.0 | S1, S7 | tested: bom-x and d 3.0 gives 3.0; Jackson BOM 2.22.3 with databind 2.22.4 in both orders gives 2.22.4 |
| 13 | Overriding one artifact of a BOM leaves its siblings at the BOM's version, also where the overridden artifact asks for newer. | 3.9, 3.10, 4.0 | none | tested: databind 2.22.4 gets jackson-core 2.22.3 |
| 14 | A BOM import takes what the BOM inherits from its parent as well. | 3.9 | none | tested: BOM module with the project parent managing codec 1.11; a user importing it gets codec 1.11 instead of 1.15 |
| 15 | A BOM with packaging `bom` is published as packaging `pom`, without parent, with only its own managed dependencies. | 4.0 | S5 | tested: installed POM of a `bom` module whose parent manages codec |
| 16 | Maven 4 warns on a BOM imported from the same reactor: `BOM imports from within reactor should be avoided`. | 4.0 | S5 | tested |
| 17 | A plain version is a soft requirement; a range anywhere in the graph overrules it, also a nearer one declared in the project. | 3.9, 3.10, 4.0 | S4 | tested: d 1.0 declared, rx -> d [2.0,3.0] gives d 3.0 |
| 18 | A range resolves to the highest available version inside it. | 3.9, 3.10, 4.0 | S4 | tested: d [1.0,3.0] with 1.0, 1.5, 2.0, 3.0 available gives 3.0 |
| 19 | Ranges without a common version fail the build. | 3.9, 3.10, 4.0 | S4 | tested: `Could not resolve version conflict among …`; 3.10 and 4.0 prefix `Unsolvable hard constraint combination` |
| 20 | Ranges need repository metadata: without `maven-metadata` the build fails with `No versions available … within specified range`. | 3.9, 3.10, 4.0 | none | tested |

## Scopes

| # | Claim | Holds for | Sources | Check |
|---|---|---|---|---|
| 21 | Classpaths: `compile` main, test, runtime; `provided` main, test; `runtime` test, runtime; `test` test; `system` main, test. | 3.9, 3.10, 4.0 | S1, S4 | tested with `build-classpath` per scope |
| 22 | Transitive scope table: compile row gives compile, –, runtime, –; provided row gives provided, –, provided, –; runtime row gives runtime, –, runtime, –; test row gives test, –, test, –. | 3.9, 3.10, 4.0 | S1 | tested: s declared with each scope |
| 23 | An optional dependency of a dependency is left out. | 3.9, 3.10, 4.0 | S2, S4 | tested: `to` never reaches the project |
| 24 | A library reached through paths with different scopes gets the widest scope. | 3.9, 3.10, 4.0 | none | tested: s (test) -> tc and w -> tc give tc `compile`, in both orders |
| 25 | A library declared in the project keeps the declared scope, also when a dependency needs it with a wider one (`scope not updated to compile`). | 3.9, 3.10, 4.0 | S3 | tested: lib -> util with util declared `test`: util off main and runtime classpaths; Guice 7.0.0 with Guava `test`: Guava off the runtime classpath |
| 26 | A `system` dependency of a dependency is passed on, with scope `system` and its path. | 3.9, 3.10, 4.0 | none; S1's table leaves `system` out, S4 says "similar to provided" | tested: sy -> ts gives ts `system` on main and test classpaths |
| 27 | `systemPath` must be absolute; a relative path is an error. | 3.9, 3.10, 4.0 | S4; contradicted by S1's example | tested: `must specify an absolute path but is lib/ts.jar` |
| 28 | Maven warns for a `systemPath` inside the project: `will be unresolvable by dependent projects`. | 3.9, 3.10 | none | tested |
| 29 | Maven 3.10 warns that the `system` scope is deprecated on every use. | 3.10 | none | tested: `declares usage of deprecated 'system' scope` |
| 30 | Model 4.1.0 adds `compile-only` (main compile path), `test-only` (test compile path), `test-runtime` (test runtime path). | 4.0 | S8 | API definitions; tested with `maven-compiler-plugin` 4.0.0-beta-5: `javac.args` and `javac-test.args` hold the expected JARs |
| 31 | Plugins on the Maven 3 API put dependencies with the Maven 4 scopes on every classpath. | 4.0 | none | tested: `maven-compiler-plugin` 3.16.0, `maven-surefire-plugin` 3.6.1, `dependency:build-classpath` 3.11.0 |
| 32 | `import` works only in `<dependencyManagement>` on a dependency of type `pom`. | 3.9, 3.10, 4.0 | S1 | documented |

## Exclusions and optional dependencies

| # | Claim | Holds for | Sources | Check |
|---|---|---|---|---|
| 33 | An exclusion removes the library below the dependency it is declared on, and nowhere else. | 3.9, 3.10, 4.0 | S2, S4 | tested: b excluding d, e -> d still gives d 1.0 |
| 34 | `*:*` excludes every transitive dependency of a dependency. | 3.9, 3.10, 4.0 | S4 | tested |
| 35 | An exclusion in a published POM holds for its users. | 3.9, 3.10, 4.0 | S2 | tested: x1 -> b excluding d: the user of x1 gets no d |
| 36 | Maven has no switch to turn off transitive dependencies. | all | S6 | documented |
| 37 | `bannedDependencies` fails the build and names the path. | Enforcer 3.7.0 | S2, S9 | tested on Commons Logging below HttpClient 4.5.14 |
| 38 | `requireUpperBoundDeps` fails when a dependency gets an older version than it asks for; `dependencyConvergence` fails on any difference. | Enforcer 3.7.0 | S9 | tested: codec 1.11 against 1.15 fails both; 1.15 winning passes the first and fails the second |

## Tools

| # | Claim | Holds for | Sources | Check |
|---|---|---|---|---|
| 39 | `dependency:tree -Dincludes` takes `groupId:artifactId:type:version` patterns with `*` and commas; `excludes` the same. | dependency 3.7.0, 3.11.0 | S9 | tested: `commons-codec`, `:commons-logging`, `org.apache.*`, two patterns |
| 40 | `-Dverbose` shows the versions left out: `omitted for conflict with`, `omitted for duplicate`, `version managed from`, `scope not updated to`. | dependency 3.7.0, 3.11.0 | S3, S9 | tested |
| 41 | `mvn dependency:tree` without a version runs dependency 3.7.0 on Maven 3.9.16 and 3.11.0 on Maven 3.10.0 and 4.0.0-rc-7; the output of the examples is the same. | as stated | none | tested |
| 42 | `dependency:analyze` reports used undeclared and unused declared dependencies; runtime-only libraries show as unused. | dependency 3.7.0, 3.11.0 | S1, S9 | tested: codec used undeclared, httpclient5 unused |

## Contradictions in the sources

- Number of scopes: S1 lists six (with `import`), S4 says "There are five scopes available".
- `systemPath`: S4 says the path must be absolute (correct, #27); S1's example uses `path/to/lib/the.jar`, which fails.
- `system` scope transitivity: S1's table leaves `system` out and S4 describes it as "similar to provided", which is not transitive; a `system` dependency is passed on (#26).
- S3 says a project that declares Guava with scope `test` next to Guice "works as expected". It does for downstream projects, and for the project's tests; the project's own runtime classpath loses Guava (#25).
- S6 answers "How do I determine which POM contains missing transitive dependency?" and "How do I determine my project's transitive dependencies" with `mvn -X`; `dependency:tree` with `-Dincludes` answers both (#39).

## Not covered by any source

- Managed exclusions apply transitively (#7).
- Maven 4's use of a dependency's `<dependencyManagement>` (#9, #10).
- The widest-scope rule for libraries on several paths (#24).
- A BOM's parent leaking managed versions into its users (#14).
- The Maven 4 scopes (#30, #31): the documentation describes model 4.1.0 without them.
