---
title: Where Maven's documentation and Maven disagree
summary: What turned up while writing the guide pages of this example and running every command on Maven 3.9.16, 3.10.0 and 4.0.0-rc-7.
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

Writing the guide pages of this example meant running every command they show, on Maven 3.9.16, 3.10.0 and 4.0.0-rc-7, with JDK 21 on Linux, against an empty local repository and Maven Central, in October 2026. These are the places where what Maven did differed from what its documentation says. Each one was observed, but none was checked by a Maven committer: treat this as a list to verify, not a list of bugs.

## Getting started and the lifecycle

1. The quickstart archetype generates a `.mvn/` directory that the project trees in the getting-started pages don't show, and prints three `[WARNING] Don't override file` lines.
2. Without `-DarchetypeVersion=1.5`, `archetype:generate` uses archetype version 1.0, which generates a project for JUnit 3.8.1.
3. The getting-started guide's "How do I use external dependencies?" still shows a JUnit 4.11 POM and a log4j 1.2.12 example, and its sample output shows plugin versions that are years old (resources 3.0.2, compiler 3.8.0, surefire 2.22.1).
4. Surefire's default includes are `Test*`, `*Test`, `*Tests` and `*TestCase`; the docs leave out `*Tests`.
5. The `mvn -v` sample in *Installation* shows a "Java home:" line; current versions print "runtime:" in the Java line, and 3.10 adds the time zone.
6. Maven 4 changes how phases behave, and *Introduction to the Build Lifecycle* says nothing about it: phases form a tree with `before:` and `after:` steps, calling a phase also runs its `after:` step (`mvn integration-test` runs `post-integration-test`, `mvn compile` runs `process-classes`), and `mvn prepare-package` runs `jar:jar` on Maven 4 but not on Maven 3. The page's warning that `mvn integration-test` leaves a test server running holds only for Maven 3.
7. `src/main/filters`, `src/test/filters` and `src/assembly` are presented as part of the standard layout, but no plugin reads them by default.
8. `mvn site` on the generated quickstart project fails on 4.0.0-rc-7 with "Repository list contains duplicate entries", because of the project-info-reports plugin 3.6.1 the archetype pins; with 3.9.0 it builds.
9. The Maven 4 lifecycles reference is at `ref/4-LATEST/impl/maven-core/lifecycles.html`, not under `ref/4-LATEST/maven-core/`.
10. On 3.10.0 and 4.0.0-rc-7, `archetype:generate` prints that Central "serves path archetype-catalog.xml that its auto-discovered prefixes file denies; the prefixes file appears stale". 3.9.16 doesn't, and no page mentions it.

## Configuration, proxies and credentials

11. *Settings Reference*, Server Repository Origins ("since 3.10.0 and 4.0.0"): 3.10.0 behaves as described, but 4.0.0-rc-7 accepts the element and ignores it. Credentials still go to a repository with the same id on another host, and `strict` refuses them even when the origin is declared.
12. 3.9 reports `<repositoryOrigins>` and `<aliases>` as "Unrecognised tag": origins are ignored harmlessly, but aliased ids get no credentials and the server answers 401.
13. *Settings Reference*, Proxies: "only one may be active at a time". Several can be active; Maven uses the first active one, and `<active>` defaults to true.
14. *Settings Reference*: passwords and passphrases "must be set plain-text". Encryption and `${env.X}` both work.
15. *Configuring a proxy*: "later releases may support storing your passwords". Encrypted proxy passwords work on all three lines.
16. *Settings Reference* names two settings locations; Maven 4 also reads `.mvn/settings.xml`, where it drops `localRepository` and credentials, with warnings only under `-e`.
17. *Configuring Maven* and *Security and Deployment Settings*: "only SCP deployments and file deployments are supported". Deploying over HTTP(S) with a `<server>` is the normal case.
18. *Configuring Apache Maven* mentions only `~/.m2/settings.xml`, not the installation settings, and doesn't say that `MAVEN_OPTS` wins over `jvm.config` on Maven 3 while `jvm.config` wins on Maven 4.
19. *Configuring Apache Maven*, `jvm.config`: `#` comments work only on Maven 4; on 3.9 and 3.10 Java fails with `Could not find or load main class #`.
20. *Configuring Apache Maven* lacks `~/.m2/extensions.xml`, `conf/extensions.xml` and `MAVEN_REPO_CENTRAL`, which all exist in 3.10.
21. *Password Encryption (Maven 4)* gives the value format as `version=4.0`; 4.0.0-rc-7 writes `version=4.2`.
22. *Password Encryption (Maven 4)* doesn't say that choosing the environment-variable source means editing `$VARIABLE_NAME`.
23. A Maven 3 `<relocation>` of the master password is not followed by 4.0.0-rc-7, which stops with "Could not decrypt password". Plain Maven 3 values still decrypt, with a "legacy encrypted password(s)" warning under `-e`.
24. Piping input to `--encrypt-master-password` on 3.x silently encrypts an empty string and prints `{}`; the prompt needs a terminal.
25. *Issue Management*: the Maven Central tracker it links, issues.sonatype.org, has been closed since 2024.

## Multi-module builds

26. Both multi-module guides leave the parent out of the build-order rules: a parent that is part of the build is always built first, even when listed last.
27. A bare word in `-pl` is a relative path, never an artifactId: `-pl shop-core` fails on all three versions, `-pl :shop-core` works.
28. The `?` prefix in `-pl` works only on Maven 4; 3.9 and 3.10 reject it.
29. The Maven 4 subprojects guide's `mvn compile && mvn jetty:run -f <subproject>` doesn't work on 4.0.0-rc-7 after only `compile`: another subproject is found only after `package` copies its JAR into `.mvn/target/project-local-repo`, which Maven 4 creates itself and `mvn clean` prunes. None of this is documented.
30. *What's new in Maven 4* says the build POM is not deployed and that the consumer POM has no parent reference. On 4.0.0-rc-7 the build POM is installed and deployed as `*-build.pom`, and the consumer POM keeps `<parent>` unless flattening is turned on.
31. The docs say `<parent/>` needs model version 4.1.0; 4.0.0-rc-7 also accepts it in a 4.0.0 POM. A dependency on a sibling without a version does fail under 4.0.0.
32. Maven 4 finds a parent among the projects being built even when `<relativePath>` is wrong or empty; Maven 3 fails. *POM Reference* doesn't mention the `../pom.xml` default or that Maven checks the coordinates of the POM it finds there.
33. `-fn` prints `BUILD FAILURE` but exits with 0, and still builds the modules that depend on the failed one.
34. The link to `guide-multiple-modules-4.html` works only through a redirect in `.htaccess`.
35. `-pl app` without `-am`, for a module that isn't in the build and was never installed: 3.9.16 reports "Could not find artifact", 3.10.0 "prefixes: Path … NOT allowed from central", and 4.0.0-rc-7 adds that this "commonly happens with repository managers" and suggests disabling remote repository filtering, which is the wrong advice here.
36. While building a module selected with `-pl app`, 3.9.16 and 3.10.0 print `from pom.xml`, 4.0.0-rc-7 prints `from app/pom.xml`.

## JDKs and toolchains

37. *Guide to Using Toolchains* says `--global-toolchains` lets you put `toolchains.xml` anywhere; the user file's option is `-t`/`--toolchains`, and in Maven 4 `-gt` is deprecated for `-it`/`--install-toolchains`.
38. Its example pins toolchains plugin 1.1 and compiler 3.1 (current: 3.3.0 and 3.16.0), and it doesn't mention `select-jdk-toolchain`, JDK discovery (since toolchains plugin 3.2.0) or the per-plugin `jdkToolchain` parameter.
39. It never says that a plain `17` doesn't match `17.0.20`, or `8` match `1.8`, which matters because discovered JDKs report versions like `17.0.20` and `1.8.0_504`.
40. Its table of plugins that support toolchains, checked against every released JAR on Central: Surefire supports them since 2.4.3, not 2.5; jdiff-maven-plugin was never released; keytool-maven-plugin dropped support in 2.0.0 and its URL returns 404; protobuf-maven-plugin has had it since 0.5.0, not 0.6.1; exec uses it only in the `exec` goal and animal-sniffer only in `build`. Missing from the table: jar (3.4.0, only for the `Build-Jdk-Spec` manifest entry), jlink, jmod, jdeps and jdeprscan.
41. The toolchains plugin's JDK discovery page uses `toolchain.jdk.version` where it means `toolchain.jdk.env`, and has a broken `</properties>` closing tag.
42. Surefire's toolchains example uses `<version>8</version>`, which matches only an entry labelled `8`.

## Plugins

43. Surefire 3.6.0 (bundled with 3.10.0 and 4.0.0-rc-7) silently skips POJO tests, plain classes named `*Test` without JUnit: there is no "Tests run" line, and a failing test still gives BUILD SUCCESS. Surefire 3.5.4 on 3.9.16 runs them.
44. The Shade plugin's "Executable JAR" example says "one simply needs to set the main class"; every build also warns that `META-INF/MANIFEST.MF` overlaps, which the example doesn't mention.
45. Shade's `createDependencyReducedPom`: the docs say the reduced POM is stored next to the shaded artifact and that the copy in the project directory is temporary. `dependency-reduced-pom.xml` is written to the project directory and stays there; nothing is written to `target/`.
46. Without `clean`, when nothing changed, the jar plugin doesn't rebuild the JAR, so Shade takes its own shaded JAR as input and prints hundreds of "overlapping classes" warnings, for example on `mvn install` right after `mvn verify`. Only the jar plugin's `forceCreation` parameter documents this.
47. *Available Plugins* links the Versions Maven Plugin at `mojohaus.org/versions-maven-plugin/`, which now only redirects to `mojohaus.org/versions/versions-maven-plugin/`.

## Maven's own documentation guide

48. *Guide To Maven Documentation Style* covers two rules, the ISO 8601 date format and two-space POM indentation, and says it "has just been started". Nothing in it covers voice, kinds of pages, Maven versions or checking what a page shows.
