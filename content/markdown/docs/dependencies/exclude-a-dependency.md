---
title: Exclude a transitive dependency
summary: Keep a library that one of your dependencies brings in off your classpath, and make sure it does not come back through another path.
type: howto
since: 3.9
keywords: remove transitive dependency, unwanted jar, duplicate classes, replace commons-logging, jcl-over-slf4j, disable transitive dependencies, exclude all, wildcard exclusion, ban a dependency
terms: <exclusions> | <exclusion> | bannedDependencies | maven-enforcer-plugin
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

Use this when a dependency brings in a library you do not want: one you replace with another implementation, one whose classes clash with a library you already have, or one your code never reaches. If you only want a different version of the library, do not exclude it; [control its version](control-a-transitive-version.html) instead.

The example replaces Commons Logging, which Apache HttpClient 4 brings in, with SLF4J's drop-in replacement.

## Find the dependency that brings it in

An exclusion goes on the dependency through which the library arrives, so first find that dependency:

```
mvn dependency:tree -Dincludes=commons-logging:commons-logging
```

```
[INFO] com.example:app:jar:1.0-SNAPSHOT
[INFO] \- org.apache.httpcomponents:httpclient:jar:4.5.14:compile
[INFO]    \- commons-logging:commons-logging:jar:1.2:compile
```

The library comes in through `httpclient`. If the tree shows several paths, each of them needs an exclusion. [Find out where a dependency comes from](trace-a-dependency.html) has more on reading the tree.

## Add the exclusion

Add an `<exclusions>` element to the dependency at the first level of the tree, with the group and artifact of the library to leave out. Then add the library that replaces it:

*pom.xml*

```xml
<dependencies>
  <dependency>
    <groupId>org.apache.httpcomponents</groupId>
    <artifactId>httpclient</artifactId>
    <version>4.5.14</version>
    <exclusions>
      <exclusion>
        <groupId>commons-logging</groupId>
        <artifactId>commons-logging</artifactId>
      </exclusion>
    </exclusions>
  </dependency>
  <dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>jcl-over-slf4j</artifactId>
    <version>2.0.17</version>
  </dependency>
</dependencies>
```

An exclusion names a group and an artifact, never a version: it removes the library in every version. It also removes everything the excluded library would have brought in itself, unless another path brings that in. Run the tree again to check:

```
mvn dependency:tree
```

```
[INFO] com.example:app:jar:1.0-SNAPSHOT
[INFO] +- org.apache.httpcomponents:httpclient:jar:4.5.14:compile
[INFO] |  +- org.apache.httpcomponents:httpcore:jar:4.4.16:compile
[INFO] |  \- commons-codec:commons-codec:jar:1.11:compile
[INFO] \- org.slf4j:jcl-over-slf4j:jar:2.0.17:compile
[INFO]    \- org.slf4j:slf4j-api:jar:2.0.17:compile
```

The exclusion is part of your POM, so it also holds for projects that depend on yours: they get `httpclient` without Commons Logging as well.

## Exclude everything a dependency brings in

To take a dependency without any of its transitive dependencies, exclude `*` in both group and artifact:

*pom.xml*

```xml
<dependency>
  <groupId>org.apache.httpcomponents</groupId>
  <artifactId>httpclient</artifactId>
  <version>4.5.14</version>
  <exclusions>
    <exclusion>
      <groupId>*</groupId>
      <artifactId>*</artifactId>
    </exclusion>
  </exclusions>
</dependency>
```

You then declare yourself each library the dependency needs at runtime. Maven has no switch to turn off transitive dependencies for the whole project.

## Exclude it wherever a dependency is used

In a multi-module project, put the dependency with its exclusion in the parent's `<dependencyManagement>`. Every module that declares the dependency then gets the exclusion, and so does every place where the dependency arrives transitively:

*pom.xml*

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>org.apache.httpcomponents</groupId>
      <artifactId>httpclient</artifactId>
      <version>4.5.14</version>
      <exclusions>
        <exclusion>
          <groupId>commons-logging</groupId>
          <artifactId>commons-logging</artifactId>
        </exclusion>
      </exclusions>
    </dependency>
  </dependencies>
</dependencyManagement>
```

## Fail the build when the library comes back

An exclusion covers one path. A new dependency, or a new version of an existing one, can bring the library back through another. The `bannedDependencies` rule of the [Enforcer plugin](../../enforcer/maven-enforcer-plugin/) fails the build when the library is anywhere in the tree:

*pom.xml*

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-enforcer-plugin</artifactId>
  <version>3.7.0</version>
  <executions>
    <execution>
      <id>ban-commons-logging</id>
      <goals>
        <goal>enforce</goal>
      </goals>
      <configuration>
        <rules>
          <bannedDependencies>
            <excludes>
              <exclude>commons-logging:commons-logging</exclude>
            </excludes>
          </bannedDependencies>
        </rules>
      </configuration>
    </execution>
  </executions>
</plugin>
```

The rule runs in the `validate` phase and names the path that brought the library in:

```
[ERROR] Rule 0: org.apache.maven.enforcer.rules.dependency.BannedDependencies failed with message:
[ERROR] com.example:app:jar:1.0-SNAPSHOT
[ERROR]    org.apache.httpcomponents:httpclient:jar:4.5.14
[ERROR]       commons-logging:commons-logging:jar:1.2 <--- banned via the exclude/include list
```

Add an exclusion on that path, and the build passes again.
