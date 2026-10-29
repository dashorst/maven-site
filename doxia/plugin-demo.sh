#!/bin/bash
# Builds plugin sites with the skin of the example, the way a plugin release builds them, to show what
# the plugin sites would look like: the plugins in doxia/plugin-sites.txt, each at the release on
# maven.apache.org. The only change to a plugin is its site.xml, which names the skin; for all plugins
# at once that would be the site.xml of maven-parent. Each site ends up in target/plugin-demo/sites/
# under its path on the site (plugins/maven-compiler-plugin), and doxia/publish.sh publishes them
# there. A plugin that does not build is reported and left out. Run doxia/build.sh first: it installs
# the skin.
#
# A line of plugin-sites.txt may end in Maven options for that plugin only.
#
# Usage: doxia/plugin-demo.sh [extra Maven options, e.g. -s settings.xml]
#        PLUGINS="maven-jar-plugin maven-war-plugin" doxia/plugin-demo.sh   builds only these
set -uo pipefail
cd "$(dirname "$0")/.."
WORK=target/plugin-demo
mkdir -p "$WORK/sites" "$WORK/logs"
failed=()

while read -r path repo tag options; do
    [[ -z "$path" || "$path" == \#* ]] && continue
    [[ -n "${PLUGINS:-}" && " $PLUGINS " != *" $repo "* ]] && continue
    src="$WORK/src/$repo"
    log="$WORK/logs/$repo.log"
    rm -rf "$src" "$WORK/sites/$path"
    if ! git clone -q --depth 1 --branch "$tag" "https://github.com/apache/$repo.git" "$src" 2>"$log"; then
        failed+=("$repo (clone)"); continue
    fi
    site="$src/src/site/site.xml"
    if [[ ! -f "$site" ]]; then
        mkdir -p "$(dirname "$site")"
        printf '<?xml version="1.0" encoding="UTF-8"?>\n<site xmlns="http://maven.apache.org/SITE/2.0.0">\n  <body/>\n</site>\n' > "$site"
    fi
    # the skin of the example, instead of any the plugin names; the main site is two levels up, as
    # /plugins/<plugin>/ is on maven.apache.org
    sed -i -z 's|<skin>.*</skin>||' "$site"
    mavenSite='<mavenSite>\
      <main>../../</main>\
      <archives>https://maven.apache.org/plugins-archives/</archives>\
    </mavenSite>'
    if grep -q '<custom>' "$site"; then
        sed -i "0,/<custom>/s|<custom>|&\\
    $mavenSite|" "$site"
        custom=''
    else
        custom="<custom>\\
    $mavenSite\\
  </custom>\\
  "
    fi
    sed -i "0,/<body\\b/s|<body\\b|<skin>\\
    <groupId>io.github.dashorst.maven-site</groupId>\\
    <artifactId>maven-example-skin</artifactId>\\
    <version>1.0-SNAPSHOT</version>\\
  </skin>\\
  $custom&|" "$site"
    echo "Building $repo ($tag)"
    if (cd "$src" && mvn -B -Preporting -DskipTests -Dinvoker.skip -Drat.skip -Dcheckstyle.skip \
            -Dspotless.check.skip -Dspotless.apply.skip -Denforcer.skip -Danimal.sniffer.skip \
            ${options:-} package site "$@") >>"$log" 2>&1 && [[ -f "$src/target/site/index.html" ]]; then
        mkdir -p "$(dirname "$WORK/sites/$path")"
        mv "$src/target/site" "$WORK/sites/$path"
    else
        failed+=("$repo")
    fi
done < doxia/plugin-sites.txt

echo "Plugin sites built: $(find "$WORK/sites" -mindepth 2 -maxdepth 2 -type d | wc -l)"
if (( ${#failed[@]} )); then
    echo "Not built (see $WORK/logs/): ${failed[*]}"
fi
