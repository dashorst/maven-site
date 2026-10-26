---
title: Create your first project
type: tutorial
topic: start
summary: Check Java and Maven, generate a project from the quickstart archetype, build it into a JAR and run the program.
since: "3.9"
terms: [mvn --version, archetype:generate, maven-archetype-quickstart, mvn package, pom.xml, target]
keywords: [hello world, new project, quickstart, first build, five minutes, mvn -v, JAVA_HOME, BUILD SUCCESS, skeleton, scaffold, java -cp, getting started, prefixes file appears stale]
order: 10
source: [guides/getting-started/maven-in-five-minutes.md, guides/getting-started/index.md, install.md]
---

In this tutorial you create a small Java project with Maven, build it into a JAR file and run the program. It is the first of five tutorials that grow this one project, `my-app`, into an application with a library, a test and two modules. You need a terminal, an internet connection and a Java Development Kit (JDK) 17 or later.

## 1. Check Java and Maven

Open a terminal and check which Java you have:

```shell
java -version
```

```
openjdk version "21.0.12.1" 2026-08-18 LTS
...
```

The project you generate in the next step is compiled for Java 17, so the version must be 17 or higher.

Then check Maven:

```shell
mvn --version
```

```
Apache Maven 3.10.0 (c43a36b8d67be7e0805a411bc0898af1a51f5472)
Maven home: /opt/apache-maven-3.10.0
Java version: 21.0.12.1, vendor: Eclipse Adoptium, runtime: /usr/lib/jvm/temurin-21
Default locale: en_US, platform encoding: UTF-8, time zone: Europe/Amsterdam
OS name: "linux", version: "6.17.0", arch: "amd64", family: "unix"
```

The first line shows the Maven version. `Java version` shows the JDK that Maven runs on, and that JDK also compiles your code. Maven uses the JDK in the `JAVA_HOME` environment variable, or the `java` on your `PATH` when `JAVA_HOME` is not set. If it shows a version older than 17, point `JAVA_HOME` at a newer JDK. If the shell cannot find `mvn`, install Maven first as described in [Installation](../install.html).

> **Maven 4:** Maven 4 itself needs Java 17 or later. With an older JDK, `mvn` stops with `Error: Apache Maven 4.x requires Java 17 or newer to run.` Maven 3.9 and 3.10 run on Java 8 and later, but this project still needs 17.

## 2. Generate the project

Go to the directory where you keep your projects and run, on one line:

```shell
mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.5 -DinteractiveMode=false
```

An archetype is a project template. `archetype:generate` runs the `generate` goal of the Archetype plugin, which copies the template `maven-archetype-quickstart`, version 1.5, and fills in your `groupId` and `artifactId`. `-DinteractiveMode=false` makes it use the values on the command line instead of asking for them. Keep `-DarchetypeVersion=1.5`: without it, you get version 1.0 of the template, which generates a project for JUnit 3.

The first time, Maven prints many `Downloading from central` lines. It fetches the plugins it needs from Maven Central and keeps them in its local repository, the directory `.m2/repository` in your home directory, so later runs use those copies.

The run ends with:

```
[INFO] Project created from Archetype in dir: /home/you/projects/my-app
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

The three `[WARNING] Don't override file` lines before it are normal for this archetype. Maven 3.10 and 4 also print a warning that Maven Central's "prefixes file appears stale" for `archetype-catalog.xml`. It is about Maven Central's list of what it holds, not about your project, and you can ignore it.

## 3. Look at the generated project

Go into the new directory:

```shell
cd my-app
```

It contains:

```
my-app
|-- .mvn
|   |-- jvm.config
|   `-- maven.config
|-- pom.xml
`-- src
    |-- main
    |   `-- java
    |       `-- com
    |           `-- mycompany
    |               `-- app
    |                   `-- App.java
    `-- test
        `-- java
            `-- com
                `-- mycompany
                    `-- app
                        `-- AppTest.java
```

Your code goes in `src/main/java` and your tests in `src/test/java`. Maven knows where to look because every Maven project uses the same [directory layout](standard-directory-layout.html). The `.mvn` directory marks the top directory of the project; its two files are empty, and are where you can put options for Maven and for the JVM it runs in.

*pom.xml* describes the project. It starts with the coordinates that identify the project, and two properties:

*pom.xml*

```xml
<project ...>
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.mycompany.app</groupId>
  <artifactId>my-app</artifactId>
  <version>1.0-SNAPSHOT</version>

  <name>my-app</name>
  <!-- FIXME change it to the project's website -->
  <url>http://www.example.com</url>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <maven.compiler.release>17</maven.compiler.release>
  </properties>
  ...
</project>
```

`groupId`, `artifactId` and `version` together name what this project builds. A version that ends in `-SNAPSHOT` is still in development. `maven.compiler.release` sets the Java version to compile for, and `project.build.sourceEncoding` the encoding of your source files.

The rest of the file has two parts. `<dependencies>` lists the libraries the project uses, here JUnit Jupiter for the tests. `<build>` contains a `<pluginManagement>` section that fixes the version of each plugin the build uses, so the project builds the same way whichever Maven version runs it.

The program prints a greeting:

*src/main/java/com/mycompany/app/App.java*

```java
public class App {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }
}
```

*AppTest.java* in `src/test/java` is a test that checks nothing yet. You replace it with a real one in [Test and build your project](test-and-build.html).

## 4. Build the project

In the `my-app` directory, run:

```shell
mvn package
```

Maven compiles the code, runs the test, and packages the classes into a JAR file. The output shows one line for each step, after the downloads:

```
[INFO] --- resources:3.3.1:resources (default-resources) @ my-app ---
[INFO] --- compiler:3.13.0:compile (default-compile) @ my-app ---
[INFO] Compiling 1 source file with javac [debug release 17] to target/classes
[INFO] --- resources:3.3.1:testResources (default-testResources) @ my-app ---
[INFO] --- compiler:3.13.0:testCompile (default-testCompile) @ my-app ---
[INFO] --- surefire:3.3.0:test (default-test) @ my-app ---
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0
[INFO] --- jar:3.4.2:jar (default-jar) @ my-app ---
[INFO] Building jar: /home/you/projects/my-app/target/my-app-1.0-SNAPSHOT.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
```

`package` is a phase of the build, not a single task: Maven runs every phase before it as well, from compiling to testing, and then makes the JAR. [Phases, goals and plugins](build-lifecycle.html) explains how that works.

Everything Maven produces goes into the `target` directory: the compiled classes in `target/classes`, the compiled tests in `target/test-classes`, the test reports in `target/surefire-reports` and the JAR, `target/my-app-1.0-SNAPSHOT.jar`.

## 5. Run the program

Run the `App` class from the JAR:

```shell
java -cp target/my-app-1.0-SNAPSHOT.jar com.mycompany.app.App
```

```
Hello World!
```

You now have a Maven project that compiles, tests and packages itself with one command.

## Continue with a dependency

In the next tutorial, [Add your first dependency](add-a-dependency.html), the program uses a library from Maven Central. [Standard directory layout](standard-directory-layout.html) lists the other directories a project can have, and the [Introduction to the POM](../guides/introduction/introduction-to-the-pom.html) describes the rest of *pom.xml*.
