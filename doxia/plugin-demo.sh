#!/bin/bash
# Builds a plugin's site with the skin of the example, the way a plugin release builds it, to show what
# the plugin sites would look like: maven-compiler-plugin at its latest release. The only change to the
# plugin is its site.xml, which names the skin; for all plugins at once that would be the site.xml of
# maven-parent. The result is in target/plugin-demo/site/, published by doxia/publish.sh in
# mvn-site/plugins/maven-compiler-plugin/. Run doxia/build.sh first: it installs the skin.
#
# Usage: doxia/plugin-demo.sh [extra Maven options, e.g. -s settings.xml]
set -euo pipefail
cd "$(dirname "$0")/.."
PLUGIN=maven-compiler-plugin
TAG=maven-compiler-plugin-3.16.0
WORK=target/plugin-demo

rm -rf "$WORK"
git clone -q --depth 1 --branch "$TAG" "https://github.com/apache/$PLUGIN.git" "$WORK/$PLUGIN" 2>/dev/null
# the skin of the example; the main site is two levels up, as /plugins/<plugin>/ is on maven.apache.org
sed -i 's|^  <body>|  <skin>\
    <groupId>io.github.dashorst.maven-site</groupId>\
    <artifactId>maven-example-skin</artifactId>\
    <version>1.0-SNAPSHOT</version>\
  </skin>\
  <custom>\
    <mavenSite>\
      <main>../../</main>\
      <archives>https://maven.apache.org/plugins-archives/</archives>\
    </mavenSite>\
  </custom>\
  <body>|' "$WORK/$PLUGIN/src/site/site.xml"
(cd "$WORK/$PLUGIN" && mvn -B -Preporting -DskipTests -Dinvoker.skip -Drat.skip -Dcheckstyle.skip \
    -Dspotless.check.skip -Dspotless.apply.skip -Denforcer.skip package site "$@")
rm -rf "$WORK/site"
mv "$WORK/$PLUGIN/target/site" "$WORK/site"
