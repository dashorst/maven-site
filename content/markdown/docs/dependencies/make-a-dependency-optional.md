---
title: Make a dependency optional
summary: Let your library use a dependency for one feature without passing it on to every project that uses the library.
type: howto
since: 3.9
keywords: optional feature, library author, database driver, plugin support, not transitive, excluded by default, split into modules
terms: <optional> | <optional>true</optional>
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

Use this when you publish a library with a feature that needs another library, and most users of your library will not use that feature. A data access library that supports several databases needs every database driver to compile, but each user needs only the driver of their own database.

## Mark the dependency optional

Set `<optional>` to `true` on the dependency in your library's POM:

*pom.xml*

```xml
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <version>42.7.14</version>
  <optional>true</optional>
</dependency>
```

For your library itself nothing changes: the dependency is on its compile, test and runtime classpath as before. The difference is for the projects that depend on your library. Maven does not pass an optional dependency on to them, and `mvn dependency:tree` in such a project shows your library without it.

## Tell users what to add

A user who wants the feature declares the dependency in their own project:

*pom.xml*

```xml
<dependency>
  <groupId>org.postgresql</groupId>
  <artifactId>postgresql</artifactId>
  <version>42.7.14</version>
</dependency>
```

Nothing in Maven tells the user that this is needed; without it, the feature fails at runtime with a `ClassNotFoundException` or `NoClassDefFoundError`. Say in your library's documentation which optional dependency each feature needs, and which versions you tested with. Your code should check that the classes are present before it uses the feature, and report the missing dependency by name.

## Consider a module instead

An optional dependency leaves the work to your users. If you can, split the feature into a module of its own that has the dependency as a normal one: `mylib-core` without the driver, and `mylib-postgresql` with it. A user then picks the module for their database and gets the right driver with it, in a version you chose. [Split a project into modules](../multi-module/split-into-modules.html) shows how.

## Optional or provided

Both keep the dependency out of the projects that use your library, for different reasons:

- `<optional>true</optional>` says that your library works without the dependency, and that the user decides whether to add it.
- `<scope>provided</scope>` says that the dependency is always needed, and that the environment the code runs in supplies it, such as a servlet container that supplies the Servlet API. A provided dependency is also left out of your own runtime classpath, and so out of a WAR you build.

[Dependency scopes](scopes.html) lists what each scope does.
