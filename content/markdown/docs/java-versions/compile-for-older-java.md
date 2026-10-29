---
title: Compile for an older Java version
summary: Build classes that run on an older Java than the JDK you build with, check them against that Java's API, and run the tests on it.
type: howto
since: 3.9
keywords: Java 8, Java 11, older JDK, target version, cross-compile, javac --release, -source, -target, class file version, major version, javap, UnsupportedClassVersionError, NoSuchMethodError, bootstrap class path not set
terms: maven.compiler.release | <release> | maven.compiler.source | maven.compiler.target | maven-compiler-plugin | jdkToolchain | maven-surefire-plugin
---


Use this when your code has to run on an older Java than the JDK you build with, for example a library that still supports Java 8 while you build on JDK 21. The compiler of a newer JDK can do this by itself; you only need a second JDK to run the tests on the older Java.

## Set the release

Set the `maven.compiler.release` property to the oldest Java version the code must run on:

*pom.xml*

```xml
<properties>
  <maven.compiler.release>8</maven.compiler.release>
</properties>
```

Or set it in the configuration of the compiler plugin, which has the same effect:

*pom.xml*

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-compiler-plugin</artifactId>
  <version>3.16.0</version>
  <configuration>
    <release>8</release>
  </configuration>
</plugin>
```

The compiler plugin passes it to `javac` as `--release 8`, and the build log shows it:

```
[INFO] Compiling 1 source file with javac [debug release 8] to target/classes
```

Use the plain version number, `8`; with `1.8` the compiler stops with `release version 1.8 not supported`. The `javac` of JDK 21 adds warnings that `source value 8 is obsolete and will be removed in a future release`; they do not stop the build. A JDK supports only a limited number of older releases: the `javac` of JDK 21 accepts `8` but stops with `release version 7 not supported` for `7`. For a release your JDK no longer supports, build with an older JDK as in [Build with a different JDK than Maven runs on](build-with-another-jdk.html).

To see which Java version a class was compiled for, read its class file version with `javap` from the `target/classes` directory:

```
javap -v com/example/Greeter.class | grep major
```

```
  major version: 52
```

| Java | 8 | 11 | 17 | 21 | 25 |
|---|---|---|---|---|---|
| Major version | 52 | 55 | 61 | 65 | 69 |

## Why source and target are not enough

The older `maven.compiler.source` and `maven.compiler.target` properties set the language level and the class file version, but the code is still compiled against the class library of the JDK that runs the compiler. Code that calls a method the older Java does not have compiles without an error:

*src/main/java/com/example/Greeter.java*

```java
public String greet(String name) {
    if (name.isBlank()) {
        return "Hello";
    }
    return "Hello, " + name;
}
```

With `source` and `target` 8 on JDK 21, the build succeeds with a warning that `bootstrap class path not set in conjunction with -source 8`. The class says it is for Java 8, and fails only when Java 8 runs it:

```
Exception in thread "main" java.lang.NoSuchMethodError: java.lang.String.isBlank()Z
	at com.example.Greeter.greet(Greeter.java:5)
```

With `release` 8, the compiler checks the code against the Java 8 API and the build fails where the problem is:

```
[ERROR] /home/me/my-app/src/main/java/com/example/Greeter.java:[5,17] cannot find symbol
[ERROR]   symbol:   method isBlank()
[ERROR]   location: variable name of type java.lang.String
```

Replace `source` and `target` with `release`. When none of the three is set, the compiler plugin compiles with `source` and `target` 1.8.

## Run the tests on the older Java

`release` proves that the code compiles against the older API, not that it behaves the same on the older runtime. To run the tests on Java 8, describe a Java 8 JDK in *~/.m2/toolchains.xml*:

*~/.m2/toolchains.xml*

```xml
<toolchains>
  <toolchain>
    <type>jdk</type>
    <provides>
      <version>1.8</version>
    </provides>
    <configuration>
      <jdkHome>/opt/jdk/temurin-8</jdkHome>
    </configuration>
  </toolchain>
</toolchains>
```

and give Surefire that JDK with `jdkToolchain`:

*pom.xml*

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-surefire-plugin</artifactId>
  <version>3.6.0</version>
  <configuration>
    <jdkToolchain>
      <version>1.8</version>
    </jdkToolchain>
  </configuration>
</plugin>
```

The code is compiled by the JDK Maven runs on and tested on Java 8:

```
[INFO] Compiling 1 source file with javac [debug release 8] to target/classes
...
[INFO] Toolchain in maven-surefire-plugin: JDK[/opt/jdk/temurin-8]
```

`jdkToolchain` needs Surefire 3.0.0-M5 or later and is matched against *toolchains.xml* only. The version in it must match the `<version>` of the entry exactly, here `1.8`; use a range such as `[1.8,9)` to accept any Java 8 entry. Failsafe has the same parameter for integration tests. The test libraries must run on Java 8 as well: JUnit 6 needs Java 17, so tests on Java 8 use JUnit 5.

To run the whole build on the older JDK instead, compiler included, select it for the module with the toolchains plugin as in [Build with a different JDK than Maven runs on](build-with-another-jdk.html). With a Java 8 toolchain, the compiler plugin passes `-source` and `-target` instead of `--release`, because the `javac` of JDK 8 has no `--release` option; it compiles against the Java 8 class library either way.

## UnsupportedClassVersionError

A class compiled for a newer Java than the one that runs it does not load:

```
Exception in thread "main" java.lang.UnsupportedClassVersionError: com/example/Greeter has been compiled by a more recent version of the Java Runtime (class file version 61.0), this version of the Java Runtime only recognizes class file versions up to 52.0
```

The class was compiled for Java 17 (61) and run on Java 8 (52). Lower `release` to the version that runs the code, or run it on a newer Java. When the class in the message belongs to a dependency, that dependency needs a newer Java than your release, and you need an older version of it.
