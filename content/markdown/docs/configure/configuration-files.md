---
title: Where Maven reads its configuration
summary: Why Maven splits its configuration between the project and the machine, which files and variables each side uses, and how they combine.
type: explanation
since: 3.9
keywords: global settings, user settings, installation settings, project settings, conf directory, ~/.m2, environment variables, JVM options, command-line options, core extensions, effective settings, configuration precedence
terms: settings.xml | .mvn/maven.config | .mvn/jvm.config | .mvn/extensions.xml | .mvn/settings.xml | MAVEN_OPTS | MAVEN_ARGS | .mavenrc | maven-user.properties | maven-system.properties | help:effective-settings
---


Maven reads its configuration from two sides. The project side lives in the project's directory and in version control: the POM and the files in the *.mvn* directory. It is the same for everyone who builds the project. The machine side lives in your home directory, the Maven installation and the environment: *settings.xml* and a few environment variables. It describes this machine and this person: where artifacts come from, how the network is reached, and which credentials to use.

## The project describes the build, the machine describes the environment

A POM says what the project is and how it is built: its coordinates, dependencies, plugins and the repositories it deploys to. Everyone who checks out the project gets the same POM, and the POM is deployed with the artifact, so other builds read it too. That rules out anything that differs per machine or that must stay private. A password in a POM is published with every release.

*settings.xml* holds exactly those things: the repository manager your company mirrors Central through, the proxy your network requires, the usernames and passwords for your repositories, and the location of your local repository. None of it changes what the project is. Two developers with different settings build the same artifact.

The split also works the other way: settings cannot add project information. There is no way to set `<organization>` or `<distributionManagement>` for all projects from *settings.xml*. Information that every project of a company shares belongs in a parent POM, see [Share configuration between projects](../multi-module/share-configuration.html).

## Installation and user settings

Maven reads two *settings.xml* files:

- the installation settings, *conf/settings.xml* in the Maven installation, for everyone who uses that installation;
- the user settings, *~/.m2/settings.xml*, for you.

Neither has to exist. Maven merges them into one set of effective settings. Lists such as `<mirrors>`, `<servers>` and `<proxies>` are combined, the user's entries first. An entry with the same `id` in both files is taken from the user file, and so is a single value such as `<localRepository>`. `mvn help:effective-settings` prints the result, with passwords replaced by `***`.

The *settings.xml* that ships with Maven consists of comments and examples, with one exception: a mirror named `maven-default-http-blocker` that blocks repositories reached over plain HTTP. It appears in the effective settings of a fresh installation. If you point Maven at another installation file with `-gs`, that mirror is gone.

> **Maven 4:** The global settings are called installation settings, and the option to replace the file is `-is` (`-gs` still works, with a deprecation warning). Maven 4 also reads project settings from *.mvn/settings.xml*. They rank between the user and the installation settings, and they cannot hold `<localRepository>` or credentials: Maven drops a `<username>` or `<password>` there and reports it as a warning that only shows with `-e`.

## Options for the mvn command: .mvn/maven.config and MAVEN_ARGS

Options you would otherwise type on every `mvn` command can live in two places. *.mvn/maven.config* belongs to the project. It holds one option per line, and lines starting with `#` are comments:

*.mvn/maven.config*

```
# Settings every build of this project needs
--fail-at-end
-Dsurefire.failIfNoSpecifiedTests=false
```

Each line is one argument. `-Da=1 -Db=2` on a single line sets the property `a` to `1 -Db=2`.

The environment variable `MAVEN_ARGS` is the machine's counterpart: its options are added to every `mvn` command before the ones you type. Options on the command line win: `-Dname=value` on the command line overrides the same property from *maven.config*.

## Options for the JVM: .mvn/jvm.config and MAVEN_OPTS

Maven itself is a Java program, and some settings concern the JVM it runs in, such as the heap size. *.mvn/jvm.config* holds JVM options for the project; several options may share a line. `MAVEN_OPTS` holds them for the machine. The shell script `~/.mavenrc`, which `mvn` runs before it starts Java, is the usual place to set `MAVEN_OPTS` for all your builds; setting `MAVEN_SKIP_RC` skips it.

When both set the same option, the later one counts. Maven 3 places *jvm.config* before `MAVEN_OPTS`, so `MAVEN_OPTS` wins.

> **Maven 4:** `MAVEN_OPTS` comes first and *jvm.config* wins. Lines in *jvm.config* may contain `#` comments; Maven 3 passes a `#` to Java, which then fails with `Could not find or load main class #`.

## Extensions: .mvn/extensions.xml

Some extensions change how Maven itself works, for example a build cache or another way to resolve artifacts. They have to be loaded before Maven reads the POM, so the POM cannot declare them. They go in *.mvn/extensions.xml*, and Maven downloads them and their dependencies like any other artifact:

*.mvn/extensions.xml*

```xml
<extensions>
  <extension>
    <groupId>org.apache.maven.extensions</groupId>
    <artifactId>maven-build-cache-extension</artifactId>
    <version>1.3.0</version>
  </extension>
</extensions>
```

> **Maven 3.10 and 4:** Extensions can also be configured for the user in *~/.m2/extensions.xml* and for the installation in *conf/extensions.xml*. When the same extension appears in several files, the project file wins over the user file, and the user file over the installation file. Maven 3.9 reads only *.mvn/extensions.xml*.

## How Maven finds the .mvn directory

The *.mvn* directory sits in the top directory of the project. Maven starts in the current directory and walks up until it finds a directory that contains *.mvn*; the files in it apply even when you run Maven from a subdirectory. That is also how a multi-module build finds its root, see [Aggregation and inheritance](../multi-module/aggregation-and-inheritance.html).

## Maven 4 properties files

Maven 4 adds files for properties that would otherwise go on the command line as `-D`:

- *maven-user.properties* sets user properties, the ones `-D` sets. Maven reads it from *~/.m2* and from *.mvn*. A property in the project file overrides the same property in the user file, and `-D` on the command line overrides both.
- *maven-system.properties* sets Java system properties, from the same two directories.

The installation's own *conf/maven-system.properties* defines where Maven looks for everything else: `maven.user.conf` is *~/.m2*, `maven.project.conf` is *.mvn* and `maven.installation.conf` is *conf*, and the paths of *settings.xml*, *toolchains.xml* and *extensions.xml* are built from those three. Maven 3 ignores these files.

[Configuration files and variables](settings-files-reference.html) lists every file and variable with its location and the Maven lines that read it.
