#!/bin/bash
# Builds the example with Maven's own site tooling: installs the skin and runs `mvn site`, which also
# checks that every address the site has published still works. The result is in target/site/.
# Extra arguments go to both Maven runs, for example -s settings.xml.
set -euo pipefail
cd "$(dirname "$0")/.."
mvn -B -q -f doxia/skin/pom.xml install "$@"
mvn -B -Dspotless.skip -Drat.skip site "$@"
