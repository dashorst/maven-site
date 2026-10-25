---
title: Use a repository manager as a mirror
type: howto
topic: configure
summary: Send every download through your organisation's repository manager instead of Maven Central and the repositories projects declare.
since: "3.9"
terms: [settings.xml, <mirrors>, <mirror>, <mirrorOf>, external:*, MAVEN_REPO_CENTRAL]
keywords: [nexus, artifactory, reposilite, proxy repository, group repository, corporate repository, internal repository, replace central, maven-default-http-blocker, Blocked mirror for repositories]
order: 10
source: [guides/mini/guide-mirror-settings.md, guides/mini/guide-configuring-maven.md, repository-management.md]
---

You need this when your organisation runs a [repository manager](../repository-management.html), such as Nexus, Artifactory or Reposilite, and builds should download through it instead of reaching Maven Central and other repositories directly. The repository manager caches what it downloads, so a build gets it from the local network, and keeps working when an outside repository is slow or gone.

## Add the mirror to your settings

Ask the administrators of the repository manager for the URL of the repository that combines the outside repositories, often called a group or virtual repository. Add it as a mirror to your user settings:

*~/.m2/settings.xml*

```xml
<settings>
  <mirrors>
    <mirror>
      <id>company-repository</id>
      <name>Company repository manager</name>
      <url>https://repo.example.com/repository/maven-public/</url>
      <mirrorOf>external:*</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

- `id` is a name you choose. Maven shows it in its output, and it is the id under which you store credentials for the repository manager.
- `url` replaces the URL of every repository the mirror applies to.
- `mirrorOf` says which repositories the mirror replaces. `external:*` replaces Central and every repository a POM declares, except repositories on `localhost` and `file:` repositories, which are usually test fixtures or local copies. `*` replaces those as well. [Configuration files and variables](settings-files-reference.html#mirrorOf_patterns) lists all patterns.

A mirror replaces a repository completely. Maven does not fall back to the original URL when the mirror does not have an artifact, so the repository manager has to proxy every repository your builds need.

## Check that Maven uses the mirror

Download lines name the mirror instead of `central`. Artifacts already in your local repository are not downloaded again, so to see the lines, run a build with an empty local repository:

```
mvn -Dmaven.repo.local=/tmp/mirror-check dependency:resolve
```

```
[INFO] Downloading from company-repository: https://repo.example.com/repository/maven-public/org/apache/commons/commons-lang3/3.17.0/commons-lang3-3.17.0.pom
```

When the mirror cannot be reached, the error lists the repositories Maven had available. `central` is no longer among them:

```
[ERROR] No plugin found for prefix 'dependency' in the current project and in the plugin groups [org.apache.maven.plugins, org.codehaus.mojo] available from the repositories [local (/tmp/mirror-check), company-repository (https://repo.example.com/repository/maven-public/)]
```

If the repository manager answers with `401` or `Unauthorized`, it requires a login. Store it under the mirror's id, as described in [Store credentials for a repository](server-credentials.html).

## Leave a repository out of the mirror

To let one repository bypass the mirror, add its id with an exclamation mark, without spaces:

```xml
<mirrorOf>external:*,!partner-releases</mirrorOf>
```

Maven then connects to `partner-releases` at the URL in the POM.

To send one repository to a different mirror, add a second mirror whose `mirrorOf` names that repository's id. A mirror that names the id exactly is chosen over a wildcard mirror, whatever their order in the file.

## Repositories that use plain HTTP

Maven refuses to download from repositories with an `http://` URL, except on `localhost`. A POM that declares such a repository fails with an error from the built-in `maven-default-http-blocker` mirror:

```
Could not transfer artifact com.example:lib-http:pom:1.0 from/to maven-default-http-blocker (http://0.0.0.0/): Blocked mirror for repositories: [insecure (http://repo.partner.example/, default, releases+snapshots)]
```

A mirror in your user settings whose `mirrorOf` matches that repository, such as `external:*`, takes precedence over the blocker, so the download goes through your repository manager instead. Excluding the repository with `!` hands it back to the blocker.

## Replace only Maven Central

> **Maven 3.10 and 4:** The environment variable `MAVEN_REPO_CENTRAL`, or the property `maven.repo.central`, changes the URL Maven uses for Central, without a mirror. Repositories declared in POMs are still used directly. Maven 3.9 ignores both.
