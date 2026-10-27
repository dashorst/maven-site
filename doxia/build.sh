#!/bin/bash
# Builds the example with Maven's own site tooling: installs the skin, writes the Doxia sources
# from the Jekyll example's data, and runs `mvn site`. The result is in target/site/.
# Extra arguments go to both Maven runs, for example -s settings.xml.
set -euo pipefail
cd "$(dirname "$0")/.."
mvn -B -q -f doxia/skin/pom.xml install "$@"
python3 doxia/generate.py
mvn -B -Dspotless.skip -Drat.skip site "$@"
