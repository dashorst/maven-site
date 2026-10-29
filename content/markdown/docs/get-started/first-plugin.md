---
title: Add and configure your first plugin
summary: Add the Shade plugin to your build, bind its goal to a phase and configure it, so that your program runs with java -jar.
type: tutorial
since: 3.9
keywords: uber jar, fat jar, executable jar, runnable jar, jar with dependencies, Main-Class, manifest, ManifestResourceTransformer, plugin parameters, plugin goal, mojo, no main manifest attribute, dependency-reduced-pom.xml, overlapping resource
terms: <build> | <plugins> | <plugin> | <executions> | <execution> | <phase> | <goal> | <configuration> | maven-shade-plugin | mvn clean | java -jar
---


In this tutorial you add a plugin to the build of `my-app`, so that `mvn package` makes one JAR file with your classes and the library from [Add your first dependency](add-a-dependency.html), and that JAR runs with `java -jar`. On the way you bind a plugin goal to a phase, configure it, and look up its parameters.

Start in the `my-app` directory as you left it at the end of that tutorial.

## 1. Try to run the JAR on its own

Run the JAR the way Java runs an application:

```shell
java -jar target/my-app-1.0-SNAPSHOT.jar
```

```
no main manifest attribute, in target/my-app-1.0-SNAPSHOT.jar
```

`java -jar` reads the name of the class to start from the JAR's manifest, the file `META-INF/MANIFEST.MF` inside the JAR, and this JAR names none. It also has no room for Commons Lang: `java -jar` ignores `-cp`, so the library has to be inside the JAR.

## 2. Find the plugin

Everything a Maven build does, a plugin does. Your build already uses several: the Compiler plugin compiles, the Surefire plugin runs the tests and the JAR plugin makes the JAR. They come with the project's packaging, `jar`. For anything else, you add a plugin.

The [list of plugins](../plugins/available-plugins.html) names the plugins of the Maven project. The [Shade plugin](../../plugins/maven-shade-plugin/) packs a project and its dependencies into one JAR, and can write the main class into the manifest. Its site lists the plugin's goals and has examples; this tutorial follows its "Executable JAR" example. The current version is 3.6.2, which works with Maven 3.9, 3.10 and 4.

## 3. Add the plugin to the build

Add a `<plugins>` element to `<build>` in *pom.xml*, after `</pluginManagement>`:

*pom.xml*

```xml
<project ...>
  ...
  <build>
    <pluginManagement>
      ...
    </pluginManagement>
    <plugins>
      <plugin>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.6.2</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

A plugin in `<pluginManagement>` only gets a version; a plugin in `<plugins>` becomes part of the build. `<artifactId>` and `<version>` say which plugin and which release of it. The `<groupId>` can be left out for the plugins of the Maven project, because Maven assumes `org.apache.maven.plugins`.

A plugin does its work in goals, and the Shade plugin's goal is `shade`. The `<execution>` binds that goal to the `package` phase: every build that reaches `package` now runs `shade`, right after the JAR plugin has made the JAR.

Build the project with:

```shell
mvn clean package
```

`clean` deletes the `target` directory before the build. Use it from now on: the Shade plugin replaces the JAR with its own, and when nothing changed since the last build, the JAR plugin keeps that JAR, Shade gets its own output as input, and it warns about hundreds of overlapping classes.

The build now ends with the Shade plugin:

```
[INFO] --- jar:3.4.2:jar (default-jar) @ my-app ---
[INFO] Building jar: /home/you/projects/my-app/target/my-app-1.0-SNAPSHOT.jar
[INFO]
[INFO] --- shade:3.6.2:shade (default) @ my-app ---
[INFO] Dependency-reduced POM written at: /home/you/projects/my-app/dependency-reduced-pom.xml
[WARNING] commons-lang3-3.21.0.jar, my-app-1.0-SNAPSHOT.jar define 1 overlapping resource:
[WARNING]   - META-INF/MANIFEST.MF
...
[INFO] Replacing original artifact with shaded artifact.
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
```

`(default)` is the name of the execution, because you gave it none. The warning says that both JARs have a manifest, and that the new JAR keeps only one; that is expected here. `target/my-app-1.0-SNAPSHOT.jar` now holds the classes of Commons Lang as well, so the program runs without `target/dependency`, which `clean` removed:

```shell
java -cp target/my-app-1.0-SNAPSHOT.jar com.mycompany.app.App ada
```

```
Hello, Ada!
```

The JAR without the library is kept as `target/original-my-app-1.0-SNAPSHOT.jar`.

## 4. Configure the main class

A goal has parameters, and you set them in a `<configuration>` element. Inside an `<execution>`, the configuration applies to that execution only. Add the main class to the execution:

*pom.xml*

```xml
<execution>
  <phase>package</phase>
  <goals>
    <goal>shade</goal>
  </goals>
  <configuration>
    <transformers>
      <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
        <mainClass>com.mycompany.app.App</mainClass>
      </transformer>
    </transformers>
  </configuration>
</execution>
```

The `transformers` parameter takes a list of transformers, which change files while the Shade plugin copies them into the JAR. `ManifestResourceTransformer` writes the main class into the manifest.

Build and run the JAR:

```shell
mvn clean package
java -jar target/my-app-1.0-SNAPSHOT.jar ada
```

```
Hello, Ada!
```

## 5. Look up a parameter

List the `my-app` directory:

```shell
ls
```

```
dependency-reduced-pom.xml
pom.xml
src
target
```

The Shade plugin wrote `dependency-reduced-pom.xml`: a copy of your POM without the dependencies that are now inside the JAR, for projects that use the JAR as a library. An application does not need it.

To find out whether a plugin can leave something out, look at its goal. On the plugin's site, under "Plugin Documentation", the page of [shade:shade](../../plugins/maven-shade-plugin/shade-mojo.html) lists every parameter of the goal, with its type, its default value and what it does. One of them is `createDependencyReducedPom`, default `true`. Set it to `false` in the configuration, next to `<transformers>`. The plugin now reads:

*pom.xml*

```xml
<plugin>
  <artifactId>maven-shade-plugin</artifactId>
  <version>3.6.2</version>
  <executions>
    <execution>
      <phase>package</phase>
      <goals>
        <goal>shade</goal>
      </goals>
      <configuration>
        <transformers>
          <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
            <mainClass>com.mycompany.app.App</mainClass>
          </transformer>
        </transformers>
        <createDependencyReducedPom>false</createDependencyReducedPom>
      </configuration>
    </execution>
  </executions>
</plugin>
```

Delete the file and build again:

```shell
rm dependency-reduced-pom.xml
mvn clean package
```

The line `Dependency-reduced POM written at` is gone from the output, and so is the file. `java -jar target/my-app-1.0-SNAPSHOT.jar ada` still prints `Hello, Ada!`.

You now have a build that makes a JAR you can hand to anyone with Java, and you know where to look up what a plugin can do.

## Continue with tests

In [Test and build your project](test-and-build.html) you write a test for `Greeter` and see what the build does when it fails. [Phases, goals and plugins](build-lifecycle.html) explains how goals and phases fit together, and [Configuring plugins](../plugins/configure-plugins.html) covers configuration in full.
