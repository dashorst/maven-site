---
title: Add a dependency and a test
type: tutorial
topic: start
summary: Use a library from Maven Central in your project, test the code that uses it with JUnit, and see which libraries Maven brought in.
since: "3.9"
terms: [<dependencies>, <dependency>, <scope>, mvn verify, dependency:tree, dependency:copy-dependencies]
keywords: [library, add jar, Maven Central, central.sonatype.com, transitive dependency, JUnit 5, JUnit Jupiter, unit test, classpath, NoClassDefFoundError, package does not exist, commons-text, junit-bom]
order: 20
source: [guides/getting-started/index.md, guides/introduction/introduction-to-dependency-mechanism.md]
---

In this tutorial you make the program from [Create your first project](first-project.html) greet someone by name, using a library from Maven Central to write the name with capitals. You add the library to the project, write a test for the new code, and look at what Maven downloaded for you.

Start in the `my-app` directory as you left it at the end of that tutorial.

## 1. Find the library on Maven Central

Maven downloads libraries from Maven Central, the public repository of Java libraries. Each library has coordinates: a `groupId`, an `artifactId` and a `version`, the same three elements your own *pom.xml* starts with.

Open <https://central.sonatype.com> and search for `commons-text`. The page of `org.apache.commons:commons-text` shows the latest version and, under "Snippets", the `<dependency>` element to copy for Maven. This tutorial uses version 1.15.0.

## 2. Add the dependency

*pom.xml* has two `<dependencies>` elements: one inside `<dependencyManagement>` and one directly under `<project>`. Add the library to the one directly under `<project>`, above the JUnit dependencies:

*pom.xml*

```xml
<project ...>
  ...
  <dependencies>
    <dependency>
      <groupId>org.apache.commons</groupId>
      <artifactId>commons-text</artifactId>
      <version>1.15.0</version>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter-api</artifactId>
      <scope>test</scope>
    </dependency>
    ...
  </dependencies>
  ...
</project>
```

A dependency without a `<scope>` is available to your code, your tests and the program when it runs. The JUnit dependencies have `<scope>test</scope>`: they are only there for the tests, and do not end up with your program.

## 3. Use the library

Create a class that builds the greeting. `WordUtils.capitalizeFully` from commons-text writes every word with a capital first letter and the rest in lower case:

*src/main/java/com/mycompany/app/Greeter.java*

```java
package com.mycompany.app;

import org.apache.commons.text.WordUtils;

public class Greeter {
    public String greet(String name) {
        return "Hello, " + WordUtils.capitalizeFully(name) + "!";
    }
}
```

Replace *App.java* so that it greets the name you give on the command line, or the world when you give none:

*src/main/java/com/mycompany/app/App.java*

```java
package com.mycompany.app;

public class App {
    public static void main(String[] args) {
        String name = args.length > 0 ? String.join(" ", args) : "world";
        System.out.println(new Greeter().greet(name));
    }
}
```

Compile:

```shell
mvn compile
```

Maven downloads `commons-text-1.15.0.jar` from Central, and also `commons-lang3-3.20.0.jar`, and compiles both classes:

```
[INFO] Compiling 2 source files with javac [debug release 17] to target/classes
...
[INFO] BUILD SUCCESS
```

If the compiler reports `package org.apache.commons.text does not exist`, the dependency is in the wrong `<dependencies>` element: move it out of `<dependencyManagement>`.

## 4. Write a test

Create a test for `Greeter`:

*src/test/java/com/mycompany/app/GreeterTest.java*

```java
package com.mycompany.app;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class GreeterTest {
    @Test
    void capitalizesEveryWordOfTheName() {
        Greeter greeter = new Greeter();
        assertEquals("Hello, Ada Lovelace!", greeter.greet("ada LOVELACE"));
    }
}
```

The test uses JUnit Jupiter, the `junit-jupiter-api` dependency the project already has. Its `<dependency>` has no `<version>`: the `junit-bom` in `<dependencyManagement>` sets the version, 5.11.0, for all JUnit dependencies at once.

## 5. Build and run the tests

Run:

```shell
mvn verify
```

`verify` is the last phase before the build installs or publishes anything: Maven compiles, runs the tests, makes the JAR and then runs any checks the project has configured. It is the usual command to build a project and know that it works.

```
[INFO] Running com.mycompany.app.GreeterTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.030 s -- in com.mycompany.app.GreeterTest
[INFO] Running com.mycompany.app.AppTest
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.003 s -- in com.mycompany.app.AppTest
[INFO]
[INFO] Results:
[INFO]
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
...
[INFO] BUILD SUCCESS
```

The Surefire plugin, which runs the tests, picks up every class in `src/test/java` whose name starts with `Test` or ends in `Test`, `Tests` or `TestCase`.

## 6. Look at the dependency tree

You added one library, but Maven downloaded two. To see why, run:

```shell
mvn dependency:tree
```

```
[INFO] com.mycompany.app:my-app:jar:1.0-SNAPSHOT
[INFO] +- org.apache.commons:commons-text:jar:1.15.0:compile
[INFO] |  \- org.apache.commons:commons-lang3:jar:3.20.0:compile
[INFO] +- org.junit.jupiter:junit-jupiter-api:jar:5.11.0:test
[INFO] |  +- org.opentest4j:opentest4j:jar:1.3.0:test
[INFO] |  +- org.junit.platform:junit-platform-commons:jar:1.11.0:test
[INFO] |  \- org.apiguardian:apiguardian-api:jar:1.1.2:test
[INFO] \- org.junit.jupiter:junit-jupiter-params:jar:5.11.0:test
```

commons-text needs commons-lang3, and says so in its own POM. Maven reads that POM and adds commons-lang3 to your project as well: a transitive dependency. The last part of each line is the scope. commons-lang3 gets scope `compile` from commons-text, and the libraries that JUnit needs get scope `test` from JUnit.

## 7. Run the program

Run the program from the JAR as before:

```shell
java -cp target/my-app-1.0-SNAPSHOT.jar com.mycompany.app.App
```

```
Exception in thread "main" java.lang.NoClassDefFoundError: org/apache/commons/text/WordUtils
```

The JAR contains only your own classes. Maven puts the libraries on the classpath when it compiles and tests, but when you start the program yourself, you have to give them to `java`. Copy them into `target/dependency`, leaving out the test libraries:

```shell
mvn dependency:copy-dependencies -DincludeScope=runtime
```

Then run the program with the JAR and the libraries on the classpath:

```shell
java -cp "target/my-app-1.0-SNAPSHOT.jar:target/dependency/*" com.mycompany.app.App ada lovelace
```

```
Hello, Ada Lovelace!
```

On Windows, separate the two classpath entries with `;` instead of `:`.

You now have a project that uses a library from Maven Central, tests the code that uses it, and shows you every library it depends on.

## Continue with the build

[Phases, goals and plugins](build-lifecycle.html) explains what `mvn verify`, `mvn package` and `mvn dependency:tree` each run, and why some are phases and others goals. The [Introduction to the dependency mechanism](../guides/introduction/introduction-to-dependency-mechanism.html) covers scopes, transitive dependencies and `<dependencyManagement>` in full.
