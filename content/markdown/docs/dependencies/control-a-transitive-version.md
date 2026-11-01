---
title: Control the version of a transitive dependency
summary: Choose the version of a library that your dependencies bring in, for example to pick up a security fix, and make the build fail when a dependency needs a newer version than it gets.
type: howto
since: 3.9
keywords: override transitive version, force version, upgrade vulnerable dependency, CVE, security fix, version conflict, dependency convergence, wrong version, NoSuchMethodError, pin version
terms: <dependencyManagement> | requireUpperBoundDeps | dependencyConvergence | maven-enforcer-plugin | dependency:tree
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

Use this when a library that your dependencies bring in has the wrong version: an old one with a known vulnerability, or an older one than another dependency needs. Maven picks one version of each library for the whole project, by a rule that does not look at which version is newer; [How Maven resolves dependencies](how-dependencies-work.html#Nearest_wins) explains the rule.

The example project declares two HTTP clients. Both use Commons Codec: `httpclient` 4.5.14 asks for version 1.11 and `httpclient5` 5.1.4 for 1.15. The project gets 1.11:

```
mvn dependency:tree -Dverbose -Dincludes=commons-codec:commons-codec
```

```
[INFO] com.example:app:jar:1.0-SNAPSHOT
[INFO] +- org.apache.httpcomponents:httpclient:jar:4.5.14:compile
[INFO] |  \- commons-codec:commons-codec:jar:1.11:compile
[INFO] \- org.apache.httpcomponents.client5:httpclient5:jar:5.1.4:compile
[INFO]    \- (commons-codec:commons-codec:jar:1.15:compile - omitted for conflict with 1.11)
```

## Set the version in dependencyManagement

Add the library with the version you want to `<dependencyManagement>` in your POM:

*pom.xml*

```xml
<dependencyManagement>
  <dependencies>
    <dependency>
      <groupId>commons-codec</groupId>
      <artifactId>commons-codec</artifactId>
      <version>1.23.0</version>
    </dependency>
  </dependencies>
</dependencyManagement>
```

A managed version applies wherever the library turns up in the dependency tree, at any depth, and it wins over every version that the POMs of your dependencies ask for. It does not add the library to your project: a library that nothing brings in stays out. The tree shows where the version came from:

```
[INFO] com.example:app:jar:1.0-SNAPSHOT
[INFO] +- org.apache.httpcomponents:httpclient:jar:4.5.14:compile
[INFO] |  \- commons-codec:commons-codec:jar:1.23.0:compile (version managed from 1.11)
[INFO] \- org.apache.httpcomponents.client5:httpclient5:jar:5.1.4:compile
[INFO]    \- (commons-codec:commons-codec:jar:1.23.0:compile - version managed from 1.15; omitted for duplicate)
```

Check that the libraries that use it still work with the version you chose: a newer version can remove what an older one had. Run the tests, and read the library's release notes when you jump several versions.

In a multi-module project, put the managed version in the parent POM, so that every module gets it; see [Share dependency versions and plugin configuration](../multi-module/share-configuration.html#Manage_dependency_versions).

## Leave the scope out

Write only the coordinates and the version in a managed dependency. A `<scope>` in `<dependencyManagement>` also applies to the library where it arrives transitively. With `<scope>provided</scope>` there, a library that one of your dependencies needs at runtime silently drops off the runtime classpath, and out of the WAR or other package you build. Set a scope on the dependency in `<dependencies>` instead, where it applies only to your own declaration.

## Or declare the library yourself

If your own code uses the library, declare it as a normal dependency with the version you want:

*pom.xml*

```xml
<dependency>
  <groupId>commons-codec</groupId>
  <artifactId>commons-codec</artifactId>
  <version>1.23.0</version>
</dependency>
```

A dependency you declare is nearer to your project than any transitive one, so its version wins. Do this only for libraries your code uses: a direct dependency stays in your POM after the dependency that brought it in has dropped it, and every project that depends on yours gets it as well.

## Fail the build when a dependency gets an older version

The `requireUpperBoundDeps` rule of the [Enforcer plugin](../../enforcer/maven-enforcer-plugin/) fails the build when a dependency asks for a newer version of a library than the project gets. It catches the next conflict before it reaches production:

*pom.xml*

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-enforcer-plugin</artifactId>
  <version>3.7.0</version>
  <executions>
    <execution>
      <id>enforce-upper-bounds</id>
      <goals>
        <goal>enforce</goal>
      </goals>
      <configuration>
        <rules>
          <requireUpperBoundDeps/>
        </rules>
      </configuration>
    </execution>
  </executions>
</plugin>
```

Without the managed version, the build of the example stops in the `validate` phase and shows both paths:

```
[ERROR] Require upper bound dependencies error for commons-codec:commons-codec:1.11. Paths to dependency are:
[ERROR] +-com.example:app:1.0-SNAPSHOT
[ERROR]   +-org.apache.httpcomponents:httpclient:4.5.14
[ERROR]     +-commons-codec:commons-codec:1.11
[ERROR] and
[ERROR] +-com.example:app:1.0-SNAPSHOT
[ERROR]   +-org.apache.httpcomponents.client5:httpclient5:5.1.4
[ERROR]     +-commons-codec:commons-codec:1.15
```

The stricter `dependencyConvergence` rule fails on any difference in version, also when the project gets the newer one.
