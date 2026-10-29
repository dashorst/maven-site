#!/bin/bash
# Publishes the version built by `mvn site` on GitHub Pages of the fork, next to the Jekyll
# example: https://dashorst.github.io/maven-site/mvn-site/. Builds with doxia/build.sh and
# commits target/site/ as mvn-site/ on the gh-pages branch, kept in the worktree .gh-pages/
# (see jekyll/publish.sh, which leaves mvn-site/ in place).
#
# Usage: doxia/publish.sh [--no-push] [extra Maven options, e.g. -s settings.xml]
set -euo pipefail
cd "$(dirname "$0")/.."
REMOTE=${REMOTE:-origin}
TREE=.gh-pages
push=true
if [[ "${1:-}" == "--no-push" ]]; then push=false; shift; fi

doxia/build.sh "$@"
commit=$(git rev-parse --short HEAD)

if [[ ! -d "$TREE" ]]; then
    git fetch -q "$REMOTE" gh-pages
    git worktree add -q -B gh-pages "$TREE" "$REMOTE/gh-pages"
fi
rm -rf "$TREE/mvn-site"
cp -a target/site/. "$TREE/mvn-site/"
# GitHub Pages ignores .htaccess: a page at each moved address forwards to the new one.
classpath=$(mvn -q -B dependency:build-classpath -Dmdep.outputFile=/dev/stdout "$@")
java -cp "$classpath" src/main/java/org/apache/maven/site/check/Addresses.java pages "$TREE/mvn-site" src/published-addresses.txt
# The build links the component sites (ref, surefire, ...) to ../components/, as on the ASF
# server; GitHub Pages refuses to publish links that lead nowhere.
find "$TREE/mvn-site" -type l -delete
git -C "$TREE" add -A mvn-site
git -C "$TREE" commit -q -m "Publish doxia-demo at $commit in mvn-site/" || echo "Nothing changed."
if $push; then
    git -C "$TREE" push -q -u "$REMOTE" gh-pages
fi
