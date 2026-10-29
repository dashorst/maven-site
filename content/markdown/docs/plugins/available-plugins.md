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

# Available Plugins

Maven is - at its heart - a plugin execution framework; all work is done by plugins. Looking for a specific goal to execute? This page lists the core plugins and others. There are the build and the reporting plugins:

- **Build plugins** will be executed during the build and they should be configured in the `<build/>` element from the POM.
- **Reporting plugins** will be executed during the site generation and they should be configured in the `<reporting/>` element from the POM. Because the result of a Reporting plugin is part of the generated site, Reporting plugins should be both internationalized and localized. You can read more about the [localization of our plugins](../../extend/plugins/localization.html) and how you can help.

## Supported By The Maven Project

To see the most up-to-date list browse the Maven repository, specifically the [`org/apache/maven/plugins`](https://repo.maven.apache.org/maven2/org/apache/maven/plugins/) subdirectory. _(Plugins are organized according to a directory structure that resembles the standard Java package naming convention)_

<!-- TODO: the repository manager should be able to produce a page like this. Ensure all descriptions are in the POM of these plugins.-->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
<!-- The release dates in this table must follow the ISO-8601 standard: yyyy-MM-dd-->
<!-- See https://maven.apache.org/guides/development/guide-documentation-style.html-->
<!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->

### Core plugins

Plugins corresponding to default core phases (ie. clean, compile). They may have multiple goals as well.

<div class="plugin-list">

- **[`clean`](/plugins/maven-clean-plugin/)** · build plugin · 3.5.0, 2025-05-27 · [Source](https://github.com/apache/maven-clean-plugin/) · [Issues](https://github.com/apache/maven-clean-plugin/issues)

  Clean up after the build.

- **[`clean 4.x`](/plugins/maven-clean-plugin-4.x/)** · build plugin · 4.0.0-beta-3, 2026-10-12 · [Source](https://github.com/apache/maven-clean-plugin/) · [Issues](https://github.com/apache/maven-clean-plugin/issues)

  Clean up after the build.

- **[`compiler`](/plugins/maven-compiler-plugin/)** · build plugin · 3.16.0, 2026-08-30 · [Source](https://github.com/apache/maven-compiler-plugin/) · [Issues](https://github.com/apache/maven-compiler-plugin/issues)

  Compiles Java sources.

- **[`compiler 4.x`](/plugins/maven-compiler-plugin-4.x/)** · build plugin · 4.0.0-beta-5, 2026-08-26 · [Source](https://github.com/apache/maven-compiler-plugin/) · [Issues](https://github.com/apache/maven-compiler-plugin/issues)

  Compiles Java sources, with [Maven 4 Java Modules support](https://cwiki.apache.org/confluence/spaces/MAVEN/pages/393677487/Full+Java+Modules+Support+-+Current+State).

- **[`deploy`](/plugins/maven-deploy-plugin/)** · build plugin · 3.2.0, 2026-09-11 · [Source](https://github.com/apache/maven-deploy-plugin/) · [Issues](https://github.com/apache/maven-deploy-plugin/issues)

  Deploy the built artifact to the remote repository.

- **[`deploy 4.x`](/plugins/maven-deploy-plugin-4.x/)** · build plugin · 4.0.0-beta-3, 2026-09-11 · [Source](https://github.com/apache/maven-deploy-plugin/) · [Issues](https://github.com/apache/maven-deploy-plugin/issues)

  Deploy the built artifact to the remote repository.

- **[`failsafe`](/surefire/maven-failsafe-plugin/)** · build plugin · 3.6.0, 2026-08-31 · [Source](https://github.com/apache/maven-surefire/) · [Issues](https://github.com/apache/maven-surefire/issues)

  Run the JUnit integration tests in an isolated classloader.

- **[`install`](/plugins/maven-install-plugin/)** · build plugin · 3.2.0, 2026-09-11 · [Source](https://github.com/apache/maven-install-plugin/) · [Issues](https://github.com/apache/maven-install-plugin/issues)

  Install the built artifact into the local repository.

- **[`install 4.x`](/plugins/maven-install-plugin-4.x/)** · build plugin · 4.0.0-beta-3, 2026-09-11 · [Source](https://github.com/apache/maven-install-plugin/) · [Issues](https://github.com/apache/maven-install-plugin/issues)

  Install the built artifact into the local repository.

- **[`resources`](/plugins/maven-resources-plugin/)** · build plugin · 3.5.0, 2026-03-02 · [Source](https://github.com/apache/maven-resources-plugin/) · [Issues](https://github.com/apache/maven-resources-plugin/issues)

  Copy the resources to the output directory for including in the JAR.

- **[`resources 4.x`](/plugins/maven-resources-plugin-4.x/)** · build plugin · 4.0.0-beta-2, 2026-10-12 · [Source](https://github.com/apache/maven-resources-plugin/) · [Issues](https://github.com/apache/maven-resources-plugin/issues)

  Copy the resources to the output directory for including in the JAR.

- **[`site`](/plugins/maven-site-plugin/)** · build plugin · 3.22.0, 2026-05-20 · [Source](https://github.com/apache/maven-site-plugin/) · [Issues](https://github.com/apache/maven-site-plugin/issues)

  Generate a site for the current project.

- **[`surefire`](/surefire/maven-surefire-plugin/)** · build plugin · 3.6.0, 2026-08-31 · [Source](https://github.com/apache/maven-surefire/) · [Issues](https://github.com/apache/maven-surefire/issues)

  Run the JUnit unit tests in an isolated classloader.

</div>

### Packaging types/tools

These plugins relate to packaging respective artifact types.

<div class="plugin-list">

- **[`ear`](/plugins/maven-ear-plugin/)** · build plugin · 3.4.0, 2025-06-16 · [Source](https://github.com/apache/maven-ear-plugin/) · [Issues](https://github.com/apache/maven-ear-plugin/issues)

  Generate an EAR from the current project.

- **[`ejb`](/plugins/maven-ejb-plugin/)** · build plugin · 3.3.0, 2025-11-16 · [Source](https://github.com/apache/maven-ejb-plugin/) · [Issues](https://github.com/apache/maven-ejb-plugin/issues)

  Build an EJB (and optional client) from the current project.

- **[`jar`](/plugins/maven-jar-plugin/)** · build plugin · 3.5.1, 2026-07-19 · [Source](https://github.com/apache/maven-jar-plugin/) · [Issues](https://github.com/apache/maven-jar-plugin/issues)

  Build a JAR from the current project.

- **[`rar`](/plugins/maven-rar-plugin/)** · build plugin · 3.1.0, 2025-11-15 · [Source](https://github.com/apache/maven-rar-plugin/) · [Issues](https://github.com/apache/maven-rar-plugin/issues)

  Build a RAR from the current project.

- **[`war`](/plugins/maven-war-plugin/)** · build plugin · 3.5.1, 2025-11-24 · [Source](https://github.com/apache/maven-war-plugin/) · [Issues](https://github.com/apache/maven-war-plugin/issues)

  Build a WAR from the current project.

- **[`app-client/acr`](/plugins/maven-acr-plugin/)** · build plugin · 3.2.0, 2025-11-25 · [Source](https://github.com/apache/maven-acr-plugin/) · [Issues](https://github.com/apache/maven-acr-plugin/issues)

  Build a JavaEE application client from the current project.

- **[`shade`](/plugins/maven-shade-plugin/)** · build plugin · 3.6.2, 2026-03-02 · [Source](https://github.com/apache/maven-shade-plugin/) · [Issues](https://github.com/apache/maven-shade-plugin/issues)

  Build an Uber-JAR from the current project, including dependencies.

- **[`source`](/plugins/maven-source-plugin/)** · build plugin · 3.4.0, 2025-11-22 · [Source](https://github.com/apache/maven-source-plugin/) · [Issues](https://github.com/apache/maven-source-plugin/issues)

  Build a source-JAR from the current project.

- **[`jlink`](/plugins/maven-jlink-plugin/)** · build plugin · 3.3.0, 2026-03-09 · [Source](https://github.com/apache/maven-jlink-plugin/) · [Issues](https://github.com/apache/maven-jlink-plugin/issues)

  Build Java Run Time Image.

- **[`jmod`](/plugins/maven-jmod-plugin/)** · build plugin · 3.0.0, 2025-12-22 · [Source](https://github.com/apache/maven-jmod-plugin/) · [Issues](https://github.com/apache/maven-jmod-plugin/issues)

  Build Java JMod files.

</div>

### Reporting plugins

Plugins which generate reports, are configured as reports in the POM and run under the site generation lifecycle.

<div class="plugin-list">

- **[`changelog`](/plugins/maven-changelog-plugin/)** · reporting plugin · 3.0.0-M2, 2026-05-19 · [Source](https://github.com/apache/maven-changelog-plugin/) · [Issues](https://github.com/apache/maven-changelog-plugin/issues)

  Generate a list of recent changes from your SCM.

- **[`changes`](/plugins/maven-changes-plugin/)** · build and reporting plugin · 3.0.0-M3, 2025-05-12 · [Source](https://github.com/apache/maven-changes-plugin/) · [Issues](https://github.com/apache/maven-changes-plugin/issues)

  Generate a report from an issue tracker or a change document.

- **[`checkstyle`](/plugins/maven-checkstyle-plugin/)** · build and reporting plugin · 3.6.0, 2024-10-22 · [Source](https://github.com/apache/maven-checkstyle-plugin/) · [Issues](https://github.com/apache/maven-checkstyle-plugin/issues)

  Generate a Checkstyle report.

- **[`doap`](/plugins/maven-doap-plugin/)** · build plugin · 3.0.0-M2, 2026-09-26 · [Source](https://github.com/apache/maven-doap-plugin/) · [Issues](https://github.com/apache/maven-doap-plugin/issues)

  Generate a Description of a Project (DOAP) file from a POM.

- **[`javadoc`](/plugins/maven-javadoc-plugin/)** · build and reporting plugin · 3.12.0, 2025-09-16 · [Source](https://github.com/apache/maven-javadoc-plugin/) · [Issues](https://github.com/apache/maven-javadoc-plugin/issues)

  Generate Javadoc for the project.

- **[`jdeps`](/plugins/maven-jdeps-plugin/)** · build plugin · 3.2.0, 2025-12-28 · [Source](https://github.com/apache/maven-jdeps-plugin/) · [Issues](https://github.com/apache/maven-jdeps-plugin/issues)

  Run JDK's JDeps tool on the project.

- **[`jxr`](/jxr/maven-jxr-plugin/)** · reporting plugin · 3.6.0, 2024-10-22 · [Source](https://github.com/apache/maven-jxr/) · [Issues](https://github.com/apache/maven-jxr/issues)

  Generate a source cross reference.

- **[`pmd`](/plugins/maven-pmd-plugin/)** · build and reporting plugin · 3.28.0, 2025-10-07 · [Source](https://github.com/apache/maven-pmd-plugin/) · [Issues](https://github.com/apache/maven-pmd-plugin/issues)

  Generate a PMD/CPD report.

- **[`plugin-report`](/plugin-tools/maven-plugin-report-plugin/)** · reporting plugin · 3.16.0, 2026-09-06 · [Source](https://github.com/apache/maven-plugin-tools/) · [Issues](https://github.com/apache/maven-plugin-tools/issues)

  Create a plugin documentation for any mojos found in the source tree.

- **[`project-info-reports`](/plugins/maven-project-info-reports-plugin/)** · reporting plugin · 3.9.0, 2025-02-23 · [Source](https://github.com/apache/maven-project-info-reports-plugin/) · [Issues](https://github.com/apache/maven-project-info-reports-plugin/issues)

  Generate standard project reports.

- **[`surefire-report`](/surefire/maven-surefire-report-plugin/)** · reporting plugin · 3.6.0, 2026-08-31 · [Source](https://github.com/apache/maven-surefire/) · [Issues](https://github.com/apache/maven-surefire/issues)

  Generate a report based on the results of unit tests.

</div>

### Tools

These are miscellaneous tools available through Maven by default.

<div class="plugin-list">

- **[`antrun`](/plugins/maven-antrun-plugin/)** · build plugin · 3.2.0, 2025-10-17 · [Source](https://github.com/apache/maven-antrun-plugin/) · [Issues](https://github.com/apache/maven-antrun-plugin/issues)

  Run a set of ant tasks from a phase of the build.

- **[`artifact`](/plugins/maven-artifact-plugin/)** · build plugin · 3.7.0, 2026-09-15 · [Source](https://github.com/apache/maven-artifact-plugin/) · [Issues](https://github.com/apache/maven-artifact-plugin/issues)

  Manage Reproducible Builds tasks about artifacts.

- **[`archetype`](/archetype/maven-archetype-plugin/)** · build plugin · 3.4.1, 2025-10-03 · [Source](https://github.com/apache/maven-archetype/) · [Issues](https://github.com/apache/maven-archetype/issues)

  Generate a skeleton project structure from an archetype.

- **[`assembly`](/plugins/maven-assembly-plugin/)** · build plugin · 3.8.0, 2025-11-22 · [Source](https://github.com/apache/maven-assembly-plugin/) · [Issues](https://github.com/apache/maven-assembly-plugin/issues)

  Build an assembly (distribution) of sources and/or binaries.

- **[`dependency`](/plugins/maven-dependency-plugin/)** · build and reporting plugin · 3.11.0, 2026-05-24 · [Source](https://github.com/apache/maven-dependency-plugin/) · [Issues](https://github.com/apache/maven-dependency-plugin/issues)

  Dependency manipulation (copy, unpack) and analysis.

- **[`enforcer`](/enforcer/maven-enforcer-plugin/)** · build plugin · 3.6.3, 2026-05-15 · [Source](https://github.com/apache/maven-enforcer/) · [Issues](https://github.com/apache/maven-enforcer/issues)

  Environmental constraint checking (Maven Version, JDK etc), User Custom Rule Execution.

- **[`gpg`](/plugins/maven-gpg-plugin/)** · build plugin · 3.2.8, 2025-06-28 · [Source](https://github.com/apache/maven-gpg-plugin/) · [Issues](https://github.com/apache/maven-gpg-plugin/issues)

  Create signatures for the artifacts and poms.

- **[`help`](/plugins/maven-help-plugin/)** · build plugin · 3.5.2, 2026-06-30 · [Source](https://github.com/apache/maven-help-plugin/) · [Issues](https://github.com/apache/maven-help-plugin/issues)

  Get information about the working environment for the project.

- **[`invoker`](/plugins/maven-invoker-plugin/)** · build and reporting plugin · 3.10.1, 2026-05-02 · [Source](https://github.com/apache/maven-invoker-plugin/) · [Issues](https://github.com/apache/maven-invoker-plugin/issues)

  Run a set of Maven projects and verify the output.

- **[`jarsigner`](/plugins/maven-jarsigner-plugin/)** · build plugin · 3.1.0, 2024-09-03 · [Source](https://github.com/apache/maven-jarsigner-plugin/) · [Issues](https://github.com/apache/maven-jarsigner-plugin/issues)

  Signs or verifies project artifacts.

- **[`jdeprscan`](/plugins/maven-jdeprscan-plugin/)** · build plugin · 3.0.0, 2025-12-22 · [Source](https://github.com/apache/maven-jdeprscan-plugin/) · [Issues](https://github.com/apache/maven-jdeprscan-plugin/issues)

  Run JDK's JDeprScan tool on the project.

- **[`plugin`](/plugin-tools/maven-plugin-plugin/)** · build plugin · 3.16.0, 2026-09-06 · [Source](https://github.com/apache/maven-plugin-tools/) · [Issues](https://github.com/apache/maven-plugin-tools/issues)

  Create a Maven plugin descriptor for any mojos found in the source tree, to include in the JAR.

- **[`release`](/plugins/maven-release-plugin/)** · build plugin · 3.3.1, 2025-12-09 · [Source](https://github.com/apache/maven-release/) · [Issues](https://github.com/apache/maven-release/issues)

  Release the current project - updating the POM and tagging in the SCM.

- **[`remote-resources`](/plugins/maven-remote-resources-plugin/)** · build plugin · 3.3.0, 2024-12-30 · [Source](https://github.com/apache/maven-remote-resources-plugin/) · [Issues](https://github.com/apache/maven-remote-resources-plugin/issues)

  Copy remote resources to the output directory for inclusion in the artifact.

- **[`scm`](/scm/maven-scm-plugin/)** · build plugin · 2.2.1, 2025-09-19 · [Source](https://github.com/apache/maven-scm/) · [Issues](https://github.com/apache/maven-scm/issues)

  Execute SCM commands for the current project.

- **[`scm-publish`](/plugins/maven-scm-publish-plugin/)** · build plugin · 3.3.0, 2024-06-16 · [Source](https://github.com/apache/maven-scm-publish-plugin/) · [Issues](https://github.com/apache/maven-scm-publish-plugin/issues)

  Publish your Maven website to a scm location.

- **[`scripting`](/plugins/maven-scripting-plugin/)** · build plugin · 3.1.0, 2025-12-22 · [Source](https://github.com/apache/maven-scripting-plugin/) · [Issues](https://github.com/apache/maven-scripting-plugin/issues)

  The Maven Scripting Plugin wraps the Scripting API according to JSR223.

- **[`toolchains`](/plugins/maven-toolchains-plugin/)** · build plugin · 3.3.0, 2026-07-21 · [Source](https://github.com/apache/maven-toolchains-plugin/) · [Issues](https://github.com/apache/maven-toolchains-plugin/issues)

  Allows to share configuration across plugins.

- **[`wrapper`](/tools/wrapper/maven-wrapper-plugin/)** · build plugin · 3.3.4, 2025-09-08 · [Source](https://github.com/apache/maven-wrapper/) · [Issues](https://github.com/apache/maven-wrapper/issues)

  Download and unpack the maven wrapper distribution

</div>

\* **B**uild or **R**eporting plugin

There are also some sandbox plugins into our [source repository](https://svn.apache.org/repos/asf/maven/sandbox/trunk/plugins).

Previous archived versions of plugins reference documentations are [located here](../../plugins-archives/).

## Retired

| **Plugin**                                         | **Type*** | **Version** | **Retired Date** | **Description**                                                                                          |
|:---------------------------------------------------|:----------|:------------|:-----------------|:---------------------------------------------------------------------------------------------------------|
| [ `ant`](/plugins/maven-ant-plugin/)               | B         | 2.4         | 2019-06-02       | Generate an Ant build file for the project.                                                              |
| [ `docck`](/plugins/maven-docck-plugin/)           | B         | 1.2         | 2023-10-22       | Documentation checker plugin.                                                                            |
| [ `eclipse`](/plugins/maven-eclipse-plugin/)       | B         | 2.10        | 2015-10-07       | Generate an Eclipse project files for the current project.                                               |
| [ `idea`](/plugins/maven-idea-plugin/)             | B         | 2.2.1       | 2013-07-26       | Create/update an IDEA workspace for the current project (individual modules are created as IDEA modules) |
| [ `linkcheck`](/plugins/maven-linkcheck-plugin/)   | R         | 1.2         | 2025-09-16       | Generate a Linkcheck report of your project's documentation.                                             | 
| [ `one`](/plugins/maven-one-plugin/)               | B         | 1.3         | 2013-07-30       | A plugin for interacting with legacy Maven 1.x repositories and builds.                                  |
| [ `patch`](/plugins/maven-patch-plugin/)           | B         | 1.3         | 2024-12-10       | Use the gnu patch tool to apply patch files to source code.                                              |
| [ `pdf`](/plugins/maven-pdf-plugin/)               | B         | 1.6.2       | 2025-03-04       | Generate a PDF version of your project's documentation.                                                  |
| [ `reactor`](/plugins/maven-reactor-plugin/)       | B         | 1.1         | 2014-03-24       | Build a subset of interdependent projects in a reactor (Maven 2 only).                                   |
| [ `repository`](/plugins/maven-repository-plugin/) | B         | 2.4         | 2019-04-30       | Plugin to help with repository-based tasks.                                                              |
| [ `stage`](/plugins/maven-stage-plugin/)           | B         | 1.0         | 2025-11-29       | Assists with release staging and promotion.                                                              |
| [ `verifier`](/plugins/maven-verifier-plugin/)     | B         | 1.1         | 2025-11-29       | Useful for integration tests - verifies the existence of certain conditions.                             |

## Outside The Maven Land

### At MojoHaus (formerly known as <a id="codehaus.org"></a>codehaus.org)

There are also [many plug-ins](https://www.mojohaus.org/plugins.html) available at the [MojoHaus](https://github.com/mojohaus) project at GitHub.

Here are a few common ones:

| **Plugin** (see [complete list with version](https://www.mojohaus.org/plugins.html))      | **Description**                                                                  |
|:------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------|
| [ `animal-sniffer`](https://www.mojohaus.org/animal-sniffer/animal-sniffer-maven-plugin/) | Build signatures of APIs (JDK for example) and checks your classes against them. |
| [ `build-helper`](https://www.mojohaus.org/build-helper-maven-plugin/)                    | Attach extra artifacts and source directories to build.                          |
| [ `buildplan`](https://www.mojohaus.org/buildplan-maven-plugin/)                          | Inspect the lifecycle of your build.                                             |
| [ `castor`](https://www.mojohaus.org/castor-maven-plugin/)                                | Generate sources from an XSD using Castor.                                       |
| [ `clirr`](https://www.mojohaus.org/clirr-maven-plugin/)                                  | Compare binaries or sources for compatibility using Clirr                        |
| [ `javacc`](https://www.mojohaus.org/javacc-maven-plugin/)                                | Generate sources from a JavaCC grammar.                                          |
| [ `jdepend`](https://www.mojohaus.org/jdepend-maven-plugin/)                              | Generate a report on code metrics using JDepend.                                 |
| [ `nar-maven-plugin`](https://maven-nar.github.io/)                                       | Compiles C, C++, Fortran for different architectures.                            |
| [ `native`](https://www.mojohaus.org/maven-native/native-maven-plugin/)                   | Compiles C and C++ code with native compilers.                                   |
| [ `sql`](https://www.mojohaus.org/sql-maven-plugin/)                                      | Executes SQL scripts from files or inline.                                       |
| [ `taglist`](https://www.mojohaus.org/taglist-maven-plugin/)                              | Generate a list of tasks based on tags in your code.                             |
| [ `versions`](https://www.mojohaus.org/versions-maven-plugin/)                            | Manage versions of your project, its modules, dependencies and plugins.          |

### Misc

A number of other projects provide their own Maven plugins. This includes:

| **Plugin**                                                                                            | **Maintainer**                                                                           | **Description**                                                                                                                                    |
|:------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------|
| [ `cargo`](https://codehaus-cargo.github.io/)                                                         | [Cargo Project](https://codehaus-cargo.github.io/)                                       | Start/stop/configure J2EE containers and deploy to them.                                                                                           |
| [ `clover`](https://confluence.atlassian.com/display/CLOVER/Clover-for-Maven+2)                       | [Atlassian Clover](https://www.atlassian.com/software/clover/)                           | Generate a Clover report.                                                                                                                          |
| [ `jetty`](https://www.eclipse.org/jetty/documentation/current/jetty-maven-plugin.html)               | [Jetty Project](https://www.eclipse.org/jetty/)                                          | Jetty Run a Jetty container for rapid webapp development.                                                                                          |
| [ `jalopy`](http://www.triemax.com/products/jalopy/manual/plugin-maven.html)                          | [Triemax](http://www.triemax.com/)                                                       | Use Jalopy to format your source code.                                                                                                             |
| [ `rat`](https://creadur.apache.org/rat/)                                                             | [Apache Creadur Project](https://creadur.apache.org/)                                    | Release Audit Tool (RAT) to verify files.                                                                                                          |
| [ `Genesis Plugins`](https://geronimo.apache.org/maven/genesis/plugins/tools-maven-plugin/index.html) | [Apache Geronimo Project](https://geronimo.apache.org/)                                  | Verify legal files in artifacts.                                                                                                                   |
| [ `Apache Tomcat`](https://tomcat.apache.org/maven-plugin.html)                                       | [Apache Tomcat Project](https://tomcat.apache.org/maven-plugin.html)                     | Run an Apache Tomcat container for rapid webapp development.                                                                                       |
| [ `OWASP dependency-check`](https://dependency-check.github.io/DependencyCheck/)                      | [OWASP Dependency-check Project](https://www.owasp.org/index.php/OWASP_Dependency_Check) | Run OWASP Dependency-Check, a utility that identifies project dependencies and checks if there are any known, publicly disclosed, vulnerabilities. |
| [ `CycloneDX`](https://github.com/CycloneDX/cyclonedx-maven-plugin)                                   | [CycloneDX Project](https://cyclonedx.org/)                                              | Generate Software Bill of Materials (SBOM) in CycloneDX format.                                                                                    |
| [ `pgpverify`](https://www.simplify4u.org/pgpverify-maven-plugin/)                                    | [Simplify4U](https://www.simplify4u.org/)                                                | Verify PGP signature of all project dependencies.                                                                                                  |

## Resources

1. [Guide to Configuring Plugins](configure-plugins.html)

