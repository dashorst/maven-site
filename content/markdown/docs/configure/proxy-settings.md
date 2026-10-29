---
title: Connect through an HTTP proxy
summary: Make Maven download through the HTTP proxy your network requires, with a login if the proxy asks for one and exceptions for internal hosts.
type: howto
since: 3.9
keywords: corporate firewall, proxy server, squid, 407 Proxy Authentication Required, Connection refused, no internet access, http.proxyHost
terms: settings.xml | <proxies> | <proxy> | <nonProxyHosts>
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


You need this when your network only reaches the internet through an HTTP proxy, so that Maven fails to download from Maven Central with timeouts or `Connection refused`. If all downloads go through a [repository manager mirror](../dependencies/mirror-settings.html) inside your network, you may not need a proxy at all.

## Add the proxy to your settings

*~/.m2/settings.xml*

```xml
<settings>
  <proxies>
    <proxy>
      <id>company-proxy</id>
      <active>true</active>
      <protocol>http</protocol>
      <host>proxy.example.com</host>
      <port>3128</port>
      <nonProxyHosts>localhost|*.example.com</nonProxyHosts>
    </proxy>
  </proxies>
</settings>
```

`host` and `port` are those of the proxy, `protocol` is `http`. Maven sends requests for both `http://` and `https://` repositories through it; for HTTPS it opens a tunnel through the proxy, so the connection to the repository stays encrypted.

## Log in to the proxy

When the proxy requires a login, Maven's downloads fail with status 407:

```
[WARNING] Could not transfer metadata /.meta/prefixes.txt from/to central (https://repo.maven.apache.org/maven2): HTTP Status: 407
```

Maven 3.9 words it as `status code: 407, reason phrase: Proxy Authentication Required (407)`. Add the login to the proxy:

*~/.m2/settings.xml*

```xml
<proxy>
  <id>company-proxy</id>
  <active>true</active>
  <protocol>http</protocol>
  <host>proxy.example.com</host>
  <port>3128</port>
  <username>jdoe</username>
  <password>${env.PROXY_PASSWORD}</password>
</proxy>
```

`${env.PROXY_PASSWORD}` reads the password from an environment variable, so it is not in the file. You can also write the password itself, or an encrypted form of it, see [Encrypt passwords in settings.xml](encrypt-passwords.html).

## Reach internal hosts without the proxy

Hosts in `nonProxyHosts` are contacted directly. Separate them with `|`; `*` stands for any part of a name, as in `*.example.com`. Maven sends requests for `localhost` through the proxy too, unless you list it. Add the host of your repository manager when it is inside the network and the proxy cannot reach it.

## Check that the proxy is used

Download lines look the same with or without a proxy. The proxy shows up when something goes wrong: a failed connection names the proxy's host and port instead of the repository's.

```
[WARNING] Could not transfer metadata /.meta/prefixes.txt from/to central (https://repo.maven.apache.org/maven2): Connect to proxy.example.com:3128 [proxy.example.com/192.0.2.10] failed: Connection refused
```

That means Maven uses the proxy but cannot reach it: check the host and port. A `407` means it reached the proxy and the login is missing or wrong.

## Switch between proxies

You can declare several proxies, for example one for the office and one for home. Maven uses the first one that is active; `<active>` is `true` unless you set it to `false`. Set `<active>false</active>` on the ones you are not using.
