---
title: Test and build your project
summary: Test your code with JUnit, see what a failing test does to the build, then verify the project and install it in your local repository.
type: tutorial
since: 3.9
keywords: unit test, JUnit 5, JUnit Jupiter, assertEquals, test failure, There are test failures, BUILD FAILURE, test report, surefire report, .m2/repository, install jar locally, Tests run
terms: mvn test | mvn verify | mvn install | mvn clean | src/test/java | target/surefire-reports | maven-surefire-plugin | local repository
---

<!--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->


In this tutorial you write a test for the `Greeter` class of `my-app`, see what a failing test does to the build, and build the project the way you will from now on: verified, and installed for other projects on your machine.

Start in the `my-app` directory as you left it at the end of [Add and configure your first plugin](first-plugin.html).

## 1. Replace the placeholder test

The project came with *AppTest.java*, a test that checks nothing. Delete it:

```shell
rm src/test/java/com/mycompany/app/AppTest.java
```

Create a test for `Greeter` in its place:

*src/test/java/com/mycompany/app/GreeterTest.java*

```java
package com.mycompany.app;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class GreeterTest {

    private final Greeter greeter = new Greeter();

    @Test
    void capitalizesTheName() {
        assertEquals("Hello, Ada!", greeter.greet("ada"));
    }

    @Test
    void greetsTheWorldWithoutAName() {
        assertEquals("Hello, World!", greeter.greet(""));
    }
}
```

The tests use JUnit Jupiter, the `junit-jupiter-api` dependency the project already has. Its `<dependency>` has no `<version>`: the `junit-bom` in `<dependencyManagement>` sets the version, 5.11.0, for all JUnit dependencies at once. Each method marked `@Test` is one test, and `assertEquals` fails the test when the two values differ.

## 2. Run the tests

Run:

```shell
mvn clean test
```

`clean` removes the results of earlier builds, including those of the deleted test. `test` compiles your code and your tests and runs the tests; it makes no JAR.

```
[INFO] --- surefire:3.3.0:test (default-test) @ my-app ---
...
[INFO] Running com.mycompany.app.GreeterTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.036 s -- in com.mycompany.app.GreeterTest
[INFO]
[INFO] Results:
[INFO]
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
...
[INFO] BUILD SUCCESS
```

The Surefire plugin runs the tests. It picks up every class in `src/test/java` whose name starts with `Test` or ends in `Test`, `Tests` or `TestCase`.

## 3. Make a test fail

In *GreeterTest.java*, change the expected greeting in `capitalizesTheName` to `"Hello, ada!"` and build the JAR:

```shell
mvn package
```

```
[INFO] Running com.mycompany.app.GreeterTest
[ERROR] Tests run: 2, Failures: 1, Errors: 0, Skipped: 0, Time elapsed: 0.037 s <<< FAILURE! -- in com.mycompany.app.GreeterTest
...
[ERROR] Failures:
[ERROR]   GreeterTest.capitalizesTheName:13 expected: <Hello, ada!> but was: <Hello, Ada!>
[INFO]
[ERROR] Tests run: 2, Failures: 1, Errors: 0, Skipped: 0
[INFO]
[INFO] ------------------------------------------------------------------------
[ERROR] BUILD FAILURE
[INFO] ------------------------------------------------------------------------
...
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.3.0:test (default-test) on project my-app: There are test failures.
[ERROR]
[ERROR] Please refer to /home/you/projects/my-app/target/surefire-reports for the individual test results.
```

The summary names the test, the line in the test file and the difference. Maven stops the build at the first goal that fails, so the JAR and Shade plugins did not run: `target` has no JAR now.

## 4. Read the test report

Surefire writes a report of every test class to `target/surefire-reports`, the directory the error message points at:

```shell
ls target/surefire-reports
```

```
com.mycompany.app.GreeterTest.txt
TEST-com.mycompany.app.GreeterTest.xml
```

The `.txt` file holds the results of the class with the failure and its stack trace, as the build printed them. The `.xml` file holds the same results in a form that tools such as a CI server read. When the build output has scrolled away, or a test failed on a build server, these files tell you which test failed and why.

Change the expected greeting back to `"Hello, Ada!"`.

## 5. Build and verify the project

Run:

```shell
mvn clean verify
```

```
[INFO] --- clean:3.4.0:clean (default-clean) @ my-app ---
[INFO] --- resources:3.3.1:resources (default-resources) @ my-app ---
[INFO] --- compiler:3.13.0:compile (default-compile) @ my-app ---
[INFO] --- resources:3.3.1:testResources (default-testResources) @ my-app ---
[INFO] --- compiler:3.13.0:testCompile (default-testCompile) @ my-app ---
[INFO] --- surefire:3.3.0:test (default-test) @ my-app ---
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0
[INFO] --- jar:3.4.2:jar (default-jar) @ my-app ---
[INFO] --- shade:3.6.2:shade (default) @ my-app ---
[INFO] BUILD SUCCESS
```

You named one phase, `verify`, and Maven ran every phase before it: it compiled, tested and packaged, and then ran the checks bound to `verify`. This project has no such checks yet; projects add them for integration tests or code analysis. That makes `mvn verify` the command to run when you want to know whether a project builds and works. [Phases, goals and plugins](build-lifecycle.html) explains the phases and which goals run in each.

## 6. Install the project

Run:

```shell
mvn clean install
```

`install` is the phase after `verify`. It copies the JAR and the POM into your local repository, the directory `.m2/repository` in your home directory where Maven also keeps everything it downloads:

```
[INFO] --- install:3.1.2:install (default-install) @ my-app ---
[INFO] Installing /home/you/projects/my-app/pom.xml to /home/you/.m2/repository/com/mycompany/app/my-app/1.0-SNAPSHOT/my-app-1.0-SNAPSHOT.pom
[INFO] Installing /home/you/projects/my-app/target/my-app-1.0-SNAPSHOT.jar to /home/you/.m2/repository/com/mycompany/app/my-app/1.0-SNAPSHOT/my-app-1.0-SNAPSHOT.jar
```

The path follows the coordinates: `groupId`, `artifactId`, `version`. Another project on your machine can now use `my-app` as a dependency with those three values, as you used Commons Lang. Nobody else can: to share a project, you `deploy` it to a remote repository.

> **Maven 4:** Maven 4 installs three files. The POM from your project goes in as `my-app-1.0-SNAPSHOT-build.pom`, and `my-app-1.0-SNAPSHOT.pom` is a consumer POM that Maven 4 generates for the projects that use yours.

You now have a project with a real test, and you know what a failing test does to the build and where to find out why.

## Continue with modules

In [Split your application into modules](first-modules.html), `Greeter` and its test become a library of their own, built together with the application.
