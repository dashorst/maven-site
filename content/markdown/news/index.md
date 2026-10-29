---
title: News
summary: Releases, new tools, Maven 4 milestones, security advisories and plugin retirements, newest first.
facts: none
---

## New in the docs: POM Validation Tool (mvnval)

*2026-10-13*

mvnval checks POM files and reports every problem it finds, without running a build. Unlike mvn validate it does not stop at the first error, and its raw mode works offline. The page says it ships with Maven 4.1.0.

[Read more](../docs/plugins/mvnval.html)

## Maven 3.10.0

*2026-09-27*

Maven 3 moves to Resolver 2.x, the same lineage Maven 4 uses. Reproducible builds are on by default, and server credentials in settings.xml are now scoped to the repositories and mirrors that declare them. It still runs on Java 8.

[Read more](../downloads/releases/3.10.0.html)

## Maven 4.0.0-rc-7

*2026-09-24*

This release candidate is expected to be the last before Maven 4.0.0 GA. It contains a large number of bug fixes and improvements since rc-6, including fixes to the upgrade tool mvnup. Maven 4 needs Java 17 to run.

[Read more](../downloads/releases/4.0.0-rc-7.html)

## Maven 4.0.0-rc-6

*2026-08-04*

All known issues reported for rc-5 are fixed, including the macOS Gatekeeper problem with the JLine native library. Servers in settings.xml can declare aliases, and the default resolver transport is now Apache HttpClient.

[Read more](../downloads/releases/4.0.0-rc-6.html)

## Maven 3.10.0-rc-1

*2026-07-09*

The first release candidate of Maven 3.10 uses Resolver 2.x, turns on reproducible builds by default and allows user-wide and installation-wide extensions. Dependency classpath ordering changes from depth-first to breadth-first, as in Maven 4.

[Read more](../downloads/releases/3.10.0-rc-1.html)

## A new Maven logo

*2026-06-07*

The logo page now shows the new Maven logo received from the ASF, in SVG and PNG. There is no version for a dark background yet.

[Read more](../community/project/logos.html)

## Maven 3.9.16

*2026-05-13*

Regression fixes and other improvements from 3.9.15. Plugin prefix resolution no longer always forces a metadata download. All 3.9.x users are advised to upgrade.

[Read more](../downloads/releases/3.9.16.html)

## Maven 3.9.15

*2026-04-13*

Upgrades plexus-utils to 3.6.1 to get rid of a CVE, and makes colored console output work on Java 26 and later. All 3.9.x users are advised to upgrade.

[Read more](../downloads/releases/3.9.15.html)

## Two options for a new Maven logo

*2026-04-04*

A page shows the two logo options that were put to a vote.

[Read more](../community/project/logo-vote.html)

## Maven 3.9.14

*2026-03-12*

A quick fix for the one known issue in 3.9.13. All 3.9.x users are advised to upgrade.

[Read more](../downloads/releases/3.9.14.html)

## Maven 3.9.13

*2026-03-06*

Mostly bug and regression fixes for user-reported problems. Resolver 1.9.27 undoes the parallel PUT change from 1.9.25, because many repository managers struggled with concurrent requests, and treats HTTP 410 like 404.

[Read more](../downloads/releases/3.9.13.html)

## New in the docs: Maven null annotations

*2026-02-20*

Maven 4 has its own @Nonnull and @Nullable annotations. All Maven 4 API modules use them, and Maven DI checks them at run time. The page lists which analysis tools and IDEs support them.

[Read more](../extend/plugins/null-annotations.html)

## Maven 3.9.12

*2025-12-13*

Removes the Guice warnings on JDK 25 and later, and checks a plugin's Java version requirement before it runs, with a clear error message. Resolver 1.9.25 refines locking for parallel builds.

[Read more](../downloads/releases/3.9.12.html)

## Stage and Verifier plugins retired

*2025-11-29*

The Stage plugin (last version 1.0) assisted with release staging and promotion. The Verifier plugin (last version 1.1) verified conditions in integration tests. Both are now in the Retired list.

[Read more](../docs/plugins/available-plugins.html)

## Maven logos to follow the ASF oak leaf

*2025-11-14*

In September 2025 the ASF announced a new logo, the oak leaf, replacing the feather. The page lists every Maven logo that has to be redrawn as a result.

[Read more](../community/project/logos.html)

## Maven 4.0.0-rc-5

*2025-11-13*

Consumer POM flattening is off by default and becomes an opt-in feature, because it could cause problems when computing the dependency tree. Configuration files now use UTF-8.

[Read more](../downloads/releases/4.0.0-rc-5.html)

## New in the docs: Maven Mixins (Maven 4.1)

*2025-09-20*

Mixins will let a POM take shared configuration from several sources instead of a single parent. The page documents this planned Maven 4.1 feature.

[Read more](../docs/maven-4/mixins.html)

## Linkcheck plugin retired

*2025-09-16*

The Linkcheck plugin (last version 1.2) generated a Linkcheck report of a project's documentation. It is now in the Retired list.

[Read more](../docs/plugins/available-plugins.html)

## New in the docs: Maven Shell (mvnsh)

*2025-09-08*

Maven Shell keeps one Maven process running while the shell is open, so builds skip booting Java and Maven each time. It is built in since Maven 4.0.0 and is a technical preview that may change.

[Read more](../docs/plugins/mvnsh.html)

## New in the docs: Maven Upgrade Tool (mvnup)

*2025-07-30*

mvnup upgrades pom.xml files for Maven 4 with a check and apply workflow. It ships with Maven 4 from 4.0.0-rc-4 on, so there is nothing extra to install.

[Read more](../docs/plugins/mvnup.html)

## Maven 3.9.11

*2025-07-12*

Bug and regression fixes, and a new option to control which repositories are queried to resolve version ranges. Resolver 1.9.24 adds human-readable details for HTTP problems (RFC 9457).

[Read more](../downloads/releases/3.9.11.html)

## Maven 4.0.0-rc-4

*2025-06-18*

Introduces the Maven Upgrade Tool, which can fix pom.xml files so they work with Maven 4. Build extensions can now use DI beans.

[Read more](../downloads/releases/4.0.0-rc-4.html)

## New in the docs: Maven Dependency Injection

*2025-06-16*

Maven DI is the dependency injection framework introduced in Maven 4, the successor to Plexus and Sisu. The page shows how to use it in plugins and extensions. Plugins that use it run only on Maven 4.

[Read more](../extend/plugins/dependency-injection.html)

## Maven 3.8.9

*2025-06-14*

The release notes say to expect this to be the last release of the 3.8.x line.

[Read more](../downloads/releases/3.8.9.html)

## Maven 3.9.10

*2025-06-01*

Updates the dependencies that caused errors and warnings on Java 24, so builds run far better on Java 24. Maven still needs only Java 8 to run.

[Read more](../downloads/releases/3.9.10.html)

## New in the docs: Starting with Maven 4

*2025-04-24*

A guide to moving a build to Maven 4 in three steps: prepare with the latest Maven 3, test with the latest Maven 4 release candidate, then migrate. The page is updated as feedback from the community comes in.

[Read more](../docs/maven-4/migrate.html)

## New in the docs: Maven Daemon (mvnd)

*2025-03-14*

mvnd keeps the JVM running between builds and manages a pool of Maven processes to reduce build time. It works with existing plugins and extensions, and a native executable is available from the download page.

[Read more](../docs/plugins/mvnd.html)

## Maven 4.0.0-rc-3

*2025-03-10*

Requires Java 17 to run and is not suitable for production. It changes the new Maven 4 API in ways that plugins targeting that API need to follow.

[Read more](../downloads/releases/4.0.0-rc-3.html)

## PDF plugin retired

*2025-03-04*

The PDF plugin (last version 1.6.2) generated a PDF version of a project's documentation. It is now in the Retired list.

[Read more](../docs/plugins/available-plugins.html)

## New in the docs: What's new in Maven 4?

*2025-02-26*

An overview of Maven 4: Java 17 to run Maven, separate build and consumer POMs, model version 4.1.0, subprojects instead of modules, and lifecycle changes. The article is updated at least until Maven 4.0.0 is released.

[Read more](../docs/maven-4/whats-new.html)

## New in the docs: password encryption in Maven 4

*2025-01-28*

Maven 4 replaces the Maven 3 password encryption with a new system that has pluggable providers and the mvnenc command-line tool. A legacy provider covers a settings.xml shared with Maven 3.

[Read more](../docs/configure/encrypt-passwords.html)

## Guide updated: multiple subprojects in Maven 4

*2024-12-27*

The Maven 4 guide to the reactor now uses the new term subproject instead of module. It explains how Maven collects, sorts and builds subprojects, and how it finds the root of a build.

[Read more](../docs/multi-module/subprojects-maven-4.html)

## Patch plugin retired

*2024-12-10*

The Patch plugin (last version 1.3) used the GNU patch tool to apply patch files to source code. It is now in the Retired list.

[Read more](../docs/plugins/available-plugins.html)

## CVE-2021-26291: external HTTP repositories blocked

*2021-04-04*

POMs on Maven Central can refer to custom repositories over plain HTTP, which makes those downloads a target for man-in-the-middle attacks. Maven 3.8.1 blocks external HTTP repositories by default through a mirror in conf/settings.xml.

[Read more](../security.html)

## Zip Slip in plexus-archiver

*2018-06-05*

A crafted archive can write files outside the target directory when it is unpacked. Maven itself is not vulnerable, but several plugins that unpack dependencies with plexus-archiver were. The page lists the fixed plugin versions.

[Read more](../downloads/security/zip-slip.html)

