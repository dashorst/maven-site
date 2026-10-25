---
title: Encrypt passwords in settings.xml
type: howto
topic: configure
summary: Replace the plain passwords of servers and proxies in settings.xml with encrypted values, with a master password on Maven 3 or mvnenc on Maven 4.
since: "3.9"
terms: [settings-security.xml, settings-security4.xml, --encrypt-master-password, --encrypt-password, mvnenc, <master>, <relocation>]
keywords: [password encryption, master password, plaintext password, secrets, obfuscation, Could not decrypt password, legacy encrypted password, gpg-agent, 1password]
order: 40
source: [guides/mini/guide-encryption.md, guides/mini/guide-encryption-4.md]
---

You need this when *settings.xml* holds passwords for [servers](server-credentials.html) or [proxies](proxy-settings.html) and you do not want them readable in the file. Maven 3 and Maven 4 do this differently. The Maven 3 way also works on Maven 4, so a *settings.xml* shared between both lines uses the Maven 3 way.

What it protects against differs too. On Maven 3 the master password is itself encrypted with a key that is the same in every Maven installation, so anyone who has your *settings.xml* and *settings-security.xml* can decrypt every password. It keeps passwords out of screenshots, logs and casual reading of the file. Maven 4 uses a real cipher and takes the master password from a source you choose each time it needs it, such as a prompt, an environment variable or a password manager; its own files do not contain it.

If the build gets its passwords from a CI server, an environment variable in *settings.xml*, `${env.REPO_PASSWORD}`, may be all you need.

## Maven 3.9 and 3.10

### Create a master password

```
mvn --encrypt-master-password
```

Maven asks for the master password and prints it encrypted:

```
Master password:
{4kzViMgK7eIHk/QCyu7XNu9uRKdWi2/gowxsUw+IpcI=}
```

The output differs on every run; any of them works. Store it in *settings-security.xml* next to your *settings.xml*:

*~/.m2/settings-security.xml*

```xml
<settingsSecurity>
  <master>{4kzViMgK7eIHk/QCyu7XNu9uRKdWi2/gowxsUw+IpcI=}</master>
</settingsSecurity>
```

Do not pass the password as an argument, `mvn --encrypt-master-password secret`: it works, but it ends up in your shell history.

### Encrypt a password

```
mvn --encrypt-password
```

Maven asks for the password and prints it encrypted with your master password:

```
Password:
{Zj2I4H4i1hgH2RVpQlzuVsyYgxbynxQMYI+TrKcwwVk=}
```

Put the value, braces included, in place of the password:

*~/.m2/settings.xml*

```xml
<server>
  <id>company-releases</id>
  <username>jdoe</username>
  <password>{Zj2I4H4i1hgH2RVpQlzuVsyYgxbynxQMYI+TrKcwwVk=}</password>
</server>
```

The same works for a proxy's `<password>`. Text outside the braces is ignored, so you can leave a note: `<password>Changed 2026-10-25 {Zj2I…}</password>`.

### Keep the master password on another drive

*settings-security.xml* can point to the real file instead of holding the master password, for example on a USB drive that is only mounted when you deploy:

*~/.m2/settings-security.xml*

```xml
<settingsSecurity>
  <relocation>/media/secure-usb/settings-security.xml</relocation>
</settingsSecurity>
```

To use a different file for a single build, pass `-Dsettings.security=/path/to/settings-security.xml`.

## Maven 4

### Configure encryption with mvnenc

Maven 4 comes with `mvnenc`, in the same *bin* directory as `mvn`. Run its setup:

```
mvnenc init
```

It asks, with menus you navigate with the arrow keys:

1. **Which dispatcher you want to use as default?** Choose *Master Password Dispatcher*.
2. **Source of the master password.** Choose where Maven reads the master password each time it needs it: a password prompt, an environment variable, a file, the GPG agent, 1Password, a PinEntry prompt or a Java system property. For an environment variable, choose *Environment variable* and replace `$VARIABLE_NAME` with a name such as `MAVEN_MASTER_PASSWORD` when it asks you to edit the value.
3. **Cipher to use with master password.** Accept `AES/GCM/NoPadding`.
4. **Are values above correct?** Answer `y`.

`mvnenc` writes the choices to *~/.m2/settings-security4.xml*. The master password itself is not in it:

*~/.m2/settings-security4.xml*

```xml
<settingsSecurity xmlns="http://codehaus-plexus.github.io/plexus-sec-dispatcher/4.0.0">
  <modelVersion>4.0</modelVersion>
  <defaultDispatcher>master</defaultDispatcher>
  <configurations>
    <configuration>
      <name>master</name>
      <properties>
        <property>
          <name>source</name>
          <value>env:MAVEN_MASTER_PASSWORD</value>
        </property>
        <property>
          <name>cipher</name>
          <value>AES/GCM/NoPadding</value>
        </property>
      </properties>
    </configuration>
  </configurations>
</settingsSecurity>
```

`mvnenc diag` checks the configuration and reports each part as `VALID` or not.

### Encrypt a password with mvnenc

With the master password available from its source, for example with `MAVEN_MASTER_PASSWORD` set:

```
mvnenc encrypt
```

```
Enter the password to encrypt: ******
{[name=master,cipher=AES/GCM/NoPadding,version=4.2]bqDZtYNgylwGGMyw7QaWNgwwhP/NDPdnjAz3d7lAS0X7xYUNEuvHomqw5aTs7UqaIHw=}
```

Put the whole value in *settings.xml* as the password, as on Maven 3. `mvnenc decrypt` turns a value back into the password.

Maven needs the master password on every run that reads such a value. Without it, or with a wrong one, Maven stops before the build starts:

```
[ERROR] Error building settings
 * FATAL: Could not decrypt password (fix the corrupted password or remove it, if unused) for server company-releases
```

`mvn` itself no longer has `--encrypt-master-password` and `--encrypt-password`; Maven 4 rejects them as unrecognised options.

### Maven 3 passwords on Maven 4

Maven 4 still decrypts values made by Maven 3, using *~/.m2/settings-security.xml*, and reports them as `Detected 2 pre-Maven 4 legacy encrypted password(s)`, visible with `-e`. It does not follow a `<relocation>` in that file: with one, decrypting fails with the error above. Maven 3 cannot read values made by `mvnenc`; it sends them to the server as they are, and the server answers `401`.
