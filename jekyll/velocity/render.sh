#!/bin/bash
# Renders the Velocity templates under content/ into jekyll/.velocity/, where the Jekyll
# build reads them (see _plugins/doxia_content.rb). Needs Java 17 or later; the Velocity
# jars are downloaded from Maven Central once, into jekyll/.velocity-lib/.
set -euo pipefail
cd "$(dirname "$0")/../.."

LIB=jekyll/.velocity-lib
CENTRAL=https://repo.maven.apache.org/maven2
JARS=(
    org/apache/velocity/velocity-engine-core/2.4.1/velocity-engine-core-2.4.1.jar
    org/apache/commons/commons-lang3/3.17.0/commons-lang3-3.17.0.jar
    org/slf4j/slf4j-api/1.7.36/slf4j-api-1.7.36.jar
    org/slf4j/slf4j-nop/1.7.36/slf4j-nop-1.7.36.jar
)
mkdir -p "$LIB"
cp=()
for jar in "${JARS[@]}"; do
    file=$LIB/$(basename "$jar")
    [[ -f "$file" ]] || curl -sfL -o "$file" "$CENTRAL/$jar"
    cp+=("$file")
done

rm -rf jekyll/.velocity
java -cp "$(IFS=:; echo "${cp[*]}")" jekyll/velocity/Render.java . jekyll/.velocity
