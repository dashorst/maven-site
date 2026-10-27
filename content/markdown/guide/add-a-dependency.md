---
title: Add your first dependency
summary: Find a library on Maven Central, add it to your project's POM, use it in your code and run the program with it.
type: tutorial
since: 3.9
keywords: library, add jar, add library, central.sonatype.com, coordinates, Apache Commons Lang, commons-lang3, StringUtils, classpath, NoClassDefFoundError, package does not exist, transitive dependency
terms: <dependencies> | <dependency> | <scope> | Maven Central | dependency:copy-dependencies
---


In this tutorial you make the program from [Create your first project](first-project.html) greet someone by name. It uses a library from Maven Central, Apache Commons Lang, to write the name with a capital. You find the library, add it to the project, use it in your code and run the program with it.

Start in the `my-app` directory as you left it at the end of that tutorial.

## 1. Find the library on Maven Central

Maven downloads libraries from Maven Central, the public repository of Java libraries. Each library has coordinates: a `groupId`, an `artifactId` and a `version`, the same three elements your own *pom.xml* starts with.

Open <https://central.sonatype.com> and search for `commons-lang3`. The page of `org.apache.commons:commons-lang3` shows the latest version and, under "Snippets", the `<dependency>` element to copy for Maven. This tutorial uses version 3.21.0.

## 2. Add the dependency

*pom.xml* has two `<dependencies>` elements: one inside `<dependencyManagement>` and one directly under `<project>`. Add the library to the one directly under `<project>`, above the JUnit dependencies:

*pom.xml*

```xml
<project ...>
  ...
  <dependencies>
    <dependency>
      <groupId>org.apache.commons</groupId>
      <artifactId>commons-lang3</artifactId>
      <version>3.21.0</version>
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

Create a class that builds the greeting. `StringUtils.defaultIfBlank` from Commons Lang replaces an empty name with `world`, and `StringUtils.capitalize` writes the first letter as a capital:

*src/main/java/com/mycompany/app/Greeter.java*

```java
package com.mycompany.app;

import org.apache.commons.lang3.StringUtils;

public class Greeter {
    public String greet(String name) {
        return "Hello, " + StringUtils.capitalize(StringUtils.defaultIfBlank(name, "world")) + "!";
    }
}
```

Replace *App.java* so that it greets the name you give on the command line:

*src/main/java/com/mycompany/app/App.java*

```java
package com.mycompany.app;

public class App {
    public static void main(String[] args) {
        String name = String.join(" ", args);
        System.out.println(new Greeter().greet(name));
    }
}
```

## 4. Build the project

In the `my-app` directory, run:

```shell
mvn package
```

Maven downloads `commons-lang3-3.21.0.jar` from Maven Central into your local repository, puts it on the classpath and compiles both classes:

```
[INFO] --- compiler:3.13.0:compile (default-compile) @ my-app ---
[INFO] Compiling 2 source files with javac [debug release 17] to target/classes
...
[INFO] BUILD SUCCESS
```

If the compiler reports `package org.apache.commons.lang3 does not exist`, the dependency is in the wrong `<dependencies>` element: move it out of `<dependencyManagement>`.

Commons Lang needs no other libraries. When a library does, its own POM says so, and Maven downloads those libraries as well; [How dependencies work](../guides/introduction/introduction-to-dependency-mechanism.html) explains these transitive dependencies.

## 5. Run the program with its dependency

Run the program from the JAR as before:

```shell
java -cp target/my-app-1.0-SNAPSHOT.jar com.mycompany.app.App
```

```
Exception in thread "main" java.lang.NoClassDefFoundError: org/apache/commons/lang3/StringUtils
```

The JAR contains only your own classes. Maven puts the libraries on the classpath when it compiles and tests, but when you start the program yourself, you have to give them to `java`. Copy them into `target/dependency`, leaving out the libraries that are only for tests:

```shell
mvn dependency:copy-dependencies -DincludeScope=runtime
```

Then run the program with the JAR and the libraries on the classpath, and a name:

```shell
java -cp "target/my-app-1.0-SNAPSHOT.jar:target/dependency/*" com.mycompany.app.App ada
```

```
Hello, Ada!
```

Without a name, it prints `Hello, World!`. On Windows, separate the two classpath entries with `;` instead of `:`.

You now have a program that uses a library from Maven Central, and Maven downloads that library for anyone who builds the project.

## Continue with a plugin

Starting the program now takes a classpath with two entries. In [Add and configure your first plugin](first-plugin.html) you build one JAR that holds your classes and the library, and runs with `java -jar`.
