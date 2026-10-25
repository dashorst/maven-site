---
title: Configuration files and variables
type: reference
topic: configure
summary: Every file and environment variable Maven reads its configuration from, with location, scope and Maven line, and the patterns of mirrorOf.
since: "3.9"
terms: [settings.xml, settings-security.xml, settings-security4.xml, .mvn/maven.config, .mvn/jvm.config, .mvn/extensions.xml, .mvn/settings.xml, maven-user.properties, maven-system.properties, .mavenrc, MAVEN_OPTS, MAVEN_ARGS, MAVEN_SKIP_RC, MAVEN_REPO_CENTRAL, <mirrorOf>, -s, -gs, -is, -ps, external:*, external:http:*]
keywords: [configuration locations, conf directory, ~/.m2, user home, environment variables, mirror wildcard, exclude repository from mirror, maven-default-http-blocker, user.home]
order: 10
source: [configure.md, guides/mini/guide-mirror-settings.md, settings.md]
---

The elements of *settings.xml* are described in the [settings reference](../settings.html). [Where Maven reads its configuration](configuration-files.html) explains why the configuration is split this way.

## Files

*~* is the home directory of the user running Maven, as Java reports it in `user.home`; *conf* is the *conf* directory of the Maven installation; *.mvn* is the *.mvn* directory in the top directory of the project, the first directory upward from the current one that contains *.mvn*.

| File | Scope | Holds | Maven |
|---|---|---|---|
| *conf/settings.xml* | installation | Settings for everyone using the installation. Ships with comments and the `maven-default-http-blocker` mirror. | 3.9, 3.10, 4.0 |
| *~/.m2/settings.xml* | user | Your settings: mirrors, proxies, servers, profiles, local repository. Wins over the installation file. | 3.9, 3.10, 4.0 |
| *.mvn/settings.xml* | project | Settings for the project, ranking between user and installation; no `<localRepository>` and no credentials. | 4.0 |
| *~/.m2/settings-security.xml* | user | Encrypted master password, or a `<relocation>` to the file that holds it. | 3.9, 3.10; 4.0 reads it for Maven 3 passwords, without relocation |
| *~/.m2/settings-security4.xml* | user | Encryption configuration written by `mvnenc init`. | 4.0 |
| *~/.m2/toolchains.xml*, *conf/toolchains.xml* | user, installation | Available JDKs, see [toolchains.xml](toolchains-xml.html). | 3.9, 3.10, 4.0 |
| *.mvn/maven.config* | project | Options for `mvn`, one per line, `#` for comments. | 3.9, 3.10, 4.0 |
| *.mvn/jvm.config* | project | Options for the JVM that runs Maven. `#` comments only on 4.0. | 3.9, 3.10, 4.0 |
| *.mvn/extensions.xml* | project | Core extensions. | 3.9, 3.10, 4.0 |
| *~/.m2/extensions.xml* | user | Core extensions. | 3.10, 4.0 |
| *conf/extensions.xml* | installation | Core extensions. | 3.10, 4.0 |
| *~/.m2/maven-user.properties*, *~/.m2/maven.properties* | user | User properties, as set with `-D`. | 4.0 |
| *.mvn/maven-user.properties*, *.mvn/maven.properties* | project | User properties; win over the user files. | 4.0 |
| *~/.m2/maven-system.properties*, *.mvn/maven-system.properties* | user, project | Java system properties. | 4.0 |
| *conf/maven-system.properties*, *conf/maven-user.properties* | installation | Maven's defaults, including `maven.user.conf`, `maven.project.conf` and `maven.installation.conf`, from which the other paths are built. | 4.0 |
| *~/.mavenrc* | user | Shell script the `mvn` script runs before starting Java, usually to set `MAVEN_OPTS`. Also */etc/mavenrc* and */usr/local/etc/mavenrc*. On Windows *%USERPROFILE%\mavenrc_pre.cmd*; Maven 4 also *%USERPROFILE%\mavenrc.cmd*. | 3.9, 3.10, 4.0 |

When the same extension appears in more than one *extensions.xml*, the project file wins over the user file, and the user file over the installation file.

## Environment variables

| Variable | Holds | Maven |
|---|---|---|
| `MAVEN_OPTS` | Options for the JVM that runs Maven, such as `-Xmx2g`. Maven 3 places them after *.mvn/jvm.config*, Maven 4 before it; the later option wins. | 3.9, 3.10, 4.0 |
| `MAVEN_ARGS` | Options and goals added before the command-line arguments of every `mvn` command. | 3.9, 3.10, 4.0 |
| `MAVEN_SKIP_RC` | When set, the `mvn` script skips the *mavenrc* files. | 3.9, 3.10, 4.0 |
| `MAVEN_REPO_CENTRAL` | URL used for Maven Central instead of `https://repo.maven.apache.org/maven2`. Also the property `maven.repo.central`. | 3.10, 4.0 |
| `JAVA_HOME` | The JDK that runs Maven. | 3.9, 3.10, 4.0 |

*settings.xml* can read any environment variable as `${env.NAME}`, and any Java system property as `${name}`, such as `${user.home}`.

## Command-line options and properties for settings files

| Option or property | Effect | Maven |
|---|---|---|
| `-s`, `--settings` | Use another file as user settings. | 3.9, 3.10, 4.0 |
| `-gs`, `--global-settings` | Use another file as installation settings. Deprecated on 4.0. | 3.9, 3.10, 4.0 |
| `-is`, `--install-settings` | Use another file as installation settings. | 4.0 |
| `-ps`, `--project-settings` | Use another file as project settings. | 4.0 |
| `-Dsettings.security=` | Use another *settings-security.xml*. | 3.9, 3.10 |
| `-Dmaven.settings.security=` | Use another *settings-security4.xml*. | 4.0 |
| `-Dmaven.repo.local=` | Use another local repository directory. | 3.9, 3.10, 4.0 |

A file named with `-s`, `-gs`, `-is` or `-ps` must exist, or Maven stops with `The specified user settings file does not exist` (or `global`, `installation`). A file in a default location that does not exist is skipped.

## How settings files are merged

| Content | Result |
|---|---|
| Lists: `<mirrors>`, `<servers>`, `<proxies>`, `<profiles>` | Combined. Entries of the user file come first, then the project file (4.0), then the installation file. |
| Entries with the same `id` | Taken from the file that ranks highest: user, then project (4.0), then installation. |
| Single values, such as `<localRepository>` | Taken from the file that ranks highest. |

`mvn help:effective-settings` prints the merged settings, with passwords shown as `***`.

## mirrorOf patterns

`<mirrorOf>` holds a repository id or a pattern. Several are separated by commas, without spaces: `!repo1, *` contains the entry ` *` with a space, which matches no repository, so the mirror replaces nothing.

| Pattern | Matches |
|---|---|
| `central` | The repository with id `central`. |
| `repo1,repo2` | `repo1` and `repo2`. |
| `*` | Every repository. |
| `external:*` | Every repository except those on `localhost` and those with a `file:` URL. |
| `external:http:*` | Every repository with an `http:` URL, except those on `localhost`. The built-in `maven-default-http-blocker` mirror uses it. |
| `*,!repo1` | Every repository except `repo1`. |
| `external:*,!repo1` | Every external repository except `repo1`. |

## How Maven picks a mirror

For each repository, Maven takes at most one mirror:

1. A mirror whose `<mirrorOf>` contains the repository's id exactly, not excluded.
2. Otherwise the first mirror, in the order of the merged settings, whose pattern matches.
3. Otherwise none: Maven uses the repository's own URL.

The mirror replaces the repository completely; Maven does not fall back to the repository's URL when the mirror lacks an artifact. Because the user's mirrors come first in the merged settings, a user mirror with `external:*` takes over `http:` repositories before `maven-default-http-blocker` can block them.
