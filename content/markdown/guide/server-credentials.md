---
title: Store credentials for a repository
summary: Give Maven the username and password for a repository it downloads from or deploys to, matched to the repository by id.
type: howto
since: 3.9
keywords: 401 Unauthorized, authentication, login, deploy credentials, repository password, token, CI secrets, nexus, artifactory, mvn deploy
terms: settings.xml | <servers> | <server> | <distributionManagement> | <repositoryOrigins> | <aliases> | maven.repository.credentialScope
---


You need this when a repository asks for a login: a repository manager that only serves logged-in users, or the repository you deploy releases to. Credentials do not belong in the POM, which everyone can read and which is published with the artifact, so they go in your *settings.xml*, in a `<server>` with the same id as the repository.

## Match the server id to the repository id

Maven looks up credentials by id. When it connects to a repository, it takes the `<server>` whose `<id>` equals the id of that repository. The id comes from:

- a `<mirror>` in *settings.xml*, for downloads through a [mirror](mirror-settings.html);
- a `<repository>` in a POM, for downloads from that repository;
- the `<repository>` and `<snapshotRepository>` in the POM's `<distributionManagement>`, for `mvn deploy`.

A server whose id matches nothing is ignored without a warning, so copy the ids exactly.

## Credentials for downloading

For a repository manager configured as a mirror, use the mirror's id:

*~/.m2/settings.xml*

```xml
<settings>
  <servers>
    <server>
      <id>company-repository</id>
      <username>jdoe</username>
      <password>${env.REPO_PASSWORD}</password>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>company-repository</id>
      <url>https://repo.example.com/repository/maven-public/</url>
      <mirrorOf>external:*</mirrorOf>
    </mirror>
  </mirrors>
</settings>
```

`${env.REPO_PASSWORD}` takes the password from an environment variable, which suits a CI server that hands secrets to the build that way. You can also write the password, or a token your repository manager issued, directly, or [encrypt it](encrypt-passwords.html).

## Credentials for deploying

`mvn deploy` uploads to the repositories in the POM's `<distributionManagement>`:

*pom.xml*

```xml
<distributionManagement>
  <repository>
    <id>company-releases</id>
    <url>https://repo.example.com/repository/maven-releases/</url>
  </repository>
  <snapshotRepository>
    <id>company-snapshots</id>
    <url>https://repo.example.com/repository/maven-snapshots/</url>
  </snapshotRepository>
</distributionManagement>
```

Add a server for each id you deploy to:

*~/.m2/settings.xml*

```xml
<servers>
  <server>
    <id>company-releases</id>
    <username>jdoe</username>
    <password>${env.REPO_PASSWORD}</password>
  </server>
  <server>
    <id>company-snapshots</id>
    <username>jdoe</username>
    <password>${env.REPO_PASSWORD}</password>
  </server>
</servers>
```

## When the repository answers 401

A `401` means the repository did not accept the login, or Maven sent none:

```
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-deploy-plugin:3.2.0:deploy (default-deploy) on project creds-demo: Failed to deploy artifacts: Could not transfer artifact com.example:creds-demo:pom:1.0 from/to company-releases (https://repo.example.com/repository/maven-releases/): HTTP Status: 401
```

Maven 3.9 writes `status code: 401, reason phrase: Unauthorized (401)`. The id after `from/to` is the one Maven looked up: check that a `<server>` has exactly that id, and that the environment variable is set in the shell that runs Maven. `mvn help:effective-settings` shows which servers Maven sees, with the passwords as `***`.

## Bind credentials to hosts

> **Maven 3.10:** Maven binds a server's credentials to the hosts of the repositories and mirrors with the same id in *settings.xml*, so that a POM cannot declare a repository with your server's id on another host and receive your password. For repositories Maven only learns about from a POM, such as `<distributionManagement>`, it still sends the credentials but warns:
>
> ```
> [WARNING] Using credentials of server 'company-releases' for repository https://repo.example.com/repository/maven-releases/, although no repository or mirror with this id is declared in settings or on the command line and the server declares no <repositoryOrigins>. Declare 'https://repo.example.com' in <repositoryOrigins> of that server in settings to bind these credentials explicitly, or set maven.repository.credentialScope=strict to refuse such credential use.
> ```
>
> Declare the hosts the credentials are for in the server:
>
> ```xml
> <server>
>   <id>company-releases</id>
>   <username>jdoe</username>
>   <password>${env.REPO_PASSWORD}</password>
>   <repositoryOrigins>
>     <repositoryOrigin>https://repo.example.com</repositoryOrigin>
>   </repositoryOrigins>
> </server>
> ```
>
> A `repositoryOrigin` is a scheme, host and optional port, without a path. Credentials are then not sent to a repository with this id on another host. With `-Dmaven.repository.credentialScope=strict`, Maven also refuses credentials for servers whose hosts it does not know. Maven 3.9 reports `<repositoryOrigins>` as an unrecognised tag and ignores it, so the same file works on both lines. See [Server Repository Origins](../settings.html#Server_Repository_Origins) for the details.

> **Maven 4:** 4.0.0-rc-7 prints a similar warning but does not use `<repositoryOrigins>` yet: the warning stays, credentials are still sent to a matching id on another host, and with `strict` it refuses the credentials even when the origin is declared.

## Use one login for several ids

> **Maven 3.10 and 4:** When the same login applies to several repositories, list the other ids as aliases instead of repeating the server:
>
> ```xml
> <server>
>   <id>company-repository</id>
>   <username>jdoe</username>
>   <password>${env.REPO_PASSWORD}</password>
>   <aliases>
>     <alias>company-releases</alias>
>     <alias>company-snapshots</alias>
>   </aliases>
> </server>
> ```
>
> Maven 3.9 reports `<aliases>` as an unrecognised tag and gives the aliased ids no credentials.
