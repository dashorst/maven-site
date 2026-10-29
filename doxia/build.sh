#!/bin/bash
# Builds the example with Maven's own site tooling: installs the skin and runs `mvn site`, which also
# checks that every address the site has published still works. The result is in target/site/.
# Extra arguments go to both Maven runs, for example -s settings.xml.
set -euo pipefail
cd "$(dirname "$0")/.."
mvn -B -q -f doxia/skin/pom.xml install "$@"
# the site plugin copies a skin file only when it is newer than the copy in target/site
rm -rf target/site
mvn -B site "$@"
