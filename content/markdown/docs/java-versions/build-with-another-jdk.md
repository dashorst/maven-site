---
title: Build with a different JDK than Maven runs on
summary: Compile, test and package a project with a JDK of your choice while Maven itself keeps running on the JDK in JAVA_HOME.
type: howto
since: 3.9
keywords: JDK 17, JDK 11, Java 8, other JDK, specific JDK, switch JDK, javac version, multiple JDKs, SDKMAN, Cannot find matching toolchain definitions
terms: toolchains.xml | maven-toolchains-plugin | toolchains:toolchain | select-jdk-toolchain | display-discovered-jdk-toolchains | generate-jdk-toolchains-xml | toolchain.jdk.version | JAVA_HOME
---


Use a toolchain when the project must be built with a particular JDK and you do not want to change `JAVA_HOME`, or cannot, because Maven 4 needs Java 17 or later to run. The steps below build a project with JDK 17 while Maven runs on JDK 21. [Toolchains and the JDK Maven runs on](toolchains.html) explains how the two JDKs relate.

## Describe your JDKs in toolchains.xml

List the JDKs installed on your machine in *toolchains.xml* in the `.m2` directory of your home directory. Each `<toolchain>` names a JDK's home directory and the version you will ask for:

*~/.m2/toolchains.xml*

```xml
<toolchains>
  <toolchain>
    <type>jdk</type>
    <provides>
      <version>17</version>
      <vendor>temurin</vendor>
    </provides>
    <configuration>
      <jdkHome>/opt/jdk/temurin-17</jdkHome>
    </configuration>
  </toolchain>
  <toolchain>
    <type>jdk</type>
    <provides>
      <version>11</version>
      <vendor>temurin</vendor>
    </provides>
    <configuration>
      <jdkHome>/opt/jdk/temurin-11</jdkHome>
    </configuration>
  </toolchain>
</toolchains>
```

The version and vendor are labels you choose; Maven does not read them from the JDK. Write versions the way your POMs will ask for them: a requirement of `17` matches `<version>17</version>`, not `<version>17.0.20</version>`. [toolchains.xml](toolchains-xml.html) describes every element and how requirements match.

To start from the JDKs Maven can find on your machine, let the toolchains plugin write the entries for you, and copy the ones you want:

```
mvn toolchains:generate-jdk-toolchains-xml -Dtoolchain.file=discovered-toolchains.xml
```

The generated entries carry the full version of each JDK, such as `17.0.20`, so ask for them with a range.

## Select the JDK in the POM

Add the maven-toolchains-plugin to the build with an execution of its `toolchain` goal, and state the JDK the project needs:

*pom.xml*

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-toolchains-plugin</artifactId>
      <version>3.3.0</version>
      <executions>
        <execution>
          <goals>
            <goal>toolchain</goal>
          </goals>
        </execution>
      </executions>
      <configuration>
        <toolchains>
          <jdk>
            <version>17</version>
          </jdk>
        </toolchains>
      </configuration>
    </plugin>
  </plugins>
</build>
```

The goal runs in the `validate` phase, before anything is compiled. Add `<vendor>` next to `<version>` to require a vendor as well, or use a range such as `[17,)` to accept any JDK from 17 up; the first entry in *toolchains.xml* that matches is used. In a multi-module project, put the plugin in the parent POM so that every module is built with the same JDK.

Set the release you compile for as usual, for example with the `maven.compiler.release` property. The toolchain decides which JDK compiles; `release` decides which Java version the classes are for.

## Check which JDK compiled and ran the tests

Run the build:

```
mvn verify
```

The toolchains plugin reports the JDK it selected, and each plugin that uses it says so:

```
[INFO] --- toolchains:3.3.0:toolchain (default) @ my-app ---
[INFO] Required toolchain: jdk [ version='17' ]
[INFO] Found matching toolchain for type jdk: JDK[/opt/jdk/temurin-17]
...
[INFO] --- compiler:3.16.0:compile (default-compile) @ my-app ---
[INFO] Toolchain in maven-compiler-plugin: JDK[/opt/jdk/temurin-17]
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [forked debug release 17] to target/classes
...
[INFO] --- surefire:3.6.0:test (default-test) @ my-app ---
[INFO] Toolchain in maven-surefire-plugin: JDK[/opt/jdk/temurin-17]
```

A plugin that has no such line ran with the JDK Maven runs on. To see the Java version of the test JVM itself, print it from a test:

*src/test/java/com/example/GreeterTest.java*

```java
@Test
void greets() {
    System.out.println("Tests run on Java " + System.getProperty("java.version"));
    assertEquals("Hello, Maven", new Greeter().greet("Maven"));
}
```

```
Tests run on Java 17.0.20
```

> **Maven 4:** Output that a test writes to the console appears with the prefix `[INFO] [stdout]`.

When no entry matches, the build stops in the `validate` phase:

```
[ERROR] No toolchain matched from 2 found for type jdk
[ERROR] Cannot find matching toolchain definitions for the following toolchain types:
jdk [ version='25' ]
```

Compare the requirement with the `<provides>` of your entries, or add an entry for the JDK the project asks for.

## Select a JDK without toolchains.xml

Since version 3.2.0, the toolchains plugin can find the JDKs installed on your machine by itself. It looks in `JAVA_HOME` and in variables such as `JAVA17_HOME`, and in the directories where SDKMAN!, IntelliJ IDEA, Gradle, asdf, jenv and the operating system's packages put JDKs. List what it finds:

```
mvn toolchains:display-discovered-jdk-toolchains
```

```
[INFO] Discovered 4 JDK toolchains:
[INFO]   - /home/me/.sdkman/candidates/java/21.0.12+1.1-tem
[INFO]     provides:
[INFO]       version: 21.0.12.1
[INFO]       runtime.name: OpenJDK Runtime Environment
[INFO]       runtime.version: 21.0.12.1+1-LTS
[INFO]       vendor: Eclipse Adoptium
[INFO]       vendor.version: Temurin-21.0.12.1+1
[INFO]       current: true
[INFO]       lts: true
[INFO]       env: JAVA_HOME
[INFO]   - /home/me/.sdkman/candidates/java/17.0.20-tem
...
```

Then use the `select-jdk-toolchain` goal instead of `toolchain`, and give the version as a range in the `toolchain.jdk.version` property:

*pom.xml*

```xml
<properties>
  <toolchain.jdk.version>[17,18)</toolchain.jdk.version>
</properties>

<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-toolchains-plugin</artifactId>
      <version>3.3.0</version>
      <executions>
        <execution>
          <goals>
            <goal>select-jdk-toolchain</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

```
[INFO] --- toolchains:3.3.0:select-jdk-toolchain (default) @ my-app ---
...
[INFO] Selected JDK toolchain: JDK[/home/me/.sdkman/candidates/java/17.0.20-tem]
```

The version must be a range: a discovered JDK 17 has a version such as `17.0.20`, which a plain `17` does not match. Java 8 reports itself as `1.8.0_504`, so ask for it with `[1.8,9)`. When the JDK Maven runs on falls in the range, the goal keeps that JDK and selects no toolchain; `[17,)` on Maven running on Java 21 builds with Java 21. The goal also uses the entries of *toolchains.xml*, and it remembers what it found in *~/.m2/discovered-jdk-toolchains-cache.xml*.

To try a JDK without changing the POM, run the goal from the command line before the phase:

```
mvn toolchains:select-jdk-toolchain -Dtoolchain.jdk.version="[17,18)" verify
```

The [JDK discovery page of the plugin](../../plugins/maven-toolchains-plugin/toolchains/jdk-discovery.html) lists the other requirements it accepts, such as a vendor or an environment variable, and how it orders JDKs that all match.

## Use another JDK for one plugin

To run only the tests on another JDK, give Surefire a requirement of its own with `jdkToolchain`. It is matched against *toolchains.xml* and overrides the JDK selected for the module. [Compile for an older Java version](compile-for-older-java.html#Run_the_tests_on_the_older_Java) shows it for tests on Java 8.
