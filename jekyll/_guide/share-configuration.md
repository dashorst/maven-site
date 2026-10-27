---
title: Share dependency versions and plugin configuration
type: howto
topic: multi-module
summary: Set dependency versions, plugin versions and plugin configuration once in the parent POM, and import a BOM, so that every module uses the same.
since: "3.9"
terms: [<dependencyManagement>, <pluginManagement>, <properties>, <scope>import</scope>, BOM, help:effective-pom]
keywords: [bill of materials, version alignment, central version management, parent POM, inherit, managed dependency, lock plugin versions, Version not locked for default bindings plugins, junit-bom, duplicate versions]
order: 30
source: [guides/introduction/introduction-to-dependency-mechanism.md, guides/introduction/introduction-to-the-pom.md, pom.md]
---

Put shared versions and plugin configuration in the parent POM when several modules use the same libraries and plugins and should not drift apart. Every module that names the parent inherits what is described here; [Split a project into modules](split-into-modules.html) sets that up, and [Aggregation and inheritance](aggregation-and-inheritance.html) explains what a module inherits.

The examples use a parent `shop` with the modules `api`, `core` and `app`.

## Set a value once with a property

Properties defined in the parent are available in every module. Use them for settings that plugins read, and for version numbers you use in more than one place.

*pom.xml*

```xml
<properties>
  <maven.compiler.release>17</maven.compiler.release>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  <slf4j.version>2.0.17</slf4j.version>
</properties>
```

A module can override a property by defining it again in its own `<properties>`.

## Manage dependency versions

`<dependencyManagement>` in the parent sets the version of a dependency without adding the dependency to any module. A module that needs it declares it without a version and gets the managed one. List your own modules there as well, with `${project.version}`, so that modules can depend on each other without a version.

*pom.xml*

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>com.example.shop</groupId>
      <artifactId>api</artifactId>
      <version>${project.version}</version>
    </dependency>
    <dependency>
      <groupId>com.example.shop</groupId>
      <artifactId>core</artifactId>
      <version>${project.version}</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-api</artifactId>
      <version>${slf4j.version}</version>
    </dependency>
  </dependencies>
</dependencyManagement>
```

*core/pom.xml*

```xml
<dependencies>
  <dependency>
    <groupId>com.example.shop</groupId>
    <artifactId>api</artifactId>
  </dependency>
  <dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-api</artifactId>
  </dependency>
</dependencies>
```

The managed version also applies when the library arrives as a transitive dependency of something else. A module that writes a `<version>` in its own dependency uses that version instead of the managed one.

A dependency in the parent's `<dependencies>`, outside `<dependencyManagement>`, is added to every module. Keep that for what each module really needs.

## Import a BOM

Many libraries publish a bill of materials (BOM): a POM that holds only a `<dependencyManagement>` section with the versions of all their artifacts that belong together. Import it into the parent's `<dependencyManagement>` with type `pom` and scope `import`:

*pom.xml*

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.junit</groupId>
      <artifactId>junit-bom</artifactId>
      <version>5.14.4</version>
      <type>pom</type>
      <scope>import</scope>
    </dependency>
  </dependencies>
</dependencyManagement>
```

Modules then declare the artifacts of that library without a version:

*core/pom.xml*

```xml
<dependency>
  <groupId>org.junit.jupiter</groupId>
  <artifactId>junit-jupiter</artifactId>
  <scope>test</scope>
</dependency>
```

A version you write in `<dependencyManagement>` yourself wins over the version from an imported BOM. A POM has only one parent, but it can import any number of BOMs. The [dependency mechanism](../guides/introduction/introduction-to-dependency-mechanism.html#Importing_Dependencies) describes the rules for imports in full.

## Lock plugin versions and configure plugins

`<pluginManagement>` does for plugins what `<dependencyManagement>` does for dependencies: it sets the version and configuration of a plugin without running it. The compiler, Surefire and the other plugins of the [build lifecycle](build-lifecycle.html) run in every `jar` module anyway, so for them the managed version and configuration take effect in every module.

*pom.xml*

```xml
<build>
  <pluginManagement>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.16.0</version>
        <configuration>
          <compilerArgs>
            <arg>-Xlint:all</arg>
          </compilerArgs>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.6.0</version>
      </plugin>
    </plugins>
  </pluginManagement>
</build>
```

Without a version, each Maven release uses its own default for these plugins, so the same project builds with different plugin versions on different Maven versions.

> **Maven 4:** Maven 4 warns about every plugin of the lifecycle that has no version: `Version not locked for default bindings plugins [maven-clean-plugin, maven-resources-plugin, maven-jar-plugin], you should define versions in pluginManagement section of your pom.xml or parent`. Add those plugins to `<pluginManagement>` with a version to silence it.

## Run a plugin in some modules only

A plugin that is not part of the lifecycle runs only in modules that declare it. Put its version and executions in the parent's `<pluginManagement>`, here the source plugin that packages a jar with the sources:

*pom.xml*

```xml
<pluginManagement>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-source-plugin</artifactId>
      <version>3.4.0</version>
      <executions>
        <execution>
          <id>attach-sources</id>
          <goals>
            <goal>jar-no-fork</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</pluginManagement>
```

Then declare it, without a version, in the modules that need it:

*api/pom.xml*

```xml
<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-source-plugin</artifactId>
    </plugin>
  </plugins>
</build>
```

`mvn verify` now creates `api/target/api-1.0-SNAPSHOT-sources.jar`, and no sources jar for `core` or `app`. To run a plugin in every module instead, declare it in the parent's `<build><plugins>` rather than in `<pluginManagement>`.

## Check what a module gets

The effective POM shows a module's configuration after inheritance and imports, with every managed version filled in. In the root directory:

```
mvn help:effective-pom -pl core
```

Search the output for a dependency or plugin to see the version and configuration `core` builds with.
