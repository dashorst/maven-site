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
git -C "$TREE" add -A mvn-site
git -C "$TREE" commit -q -m "Publish doxia-demo at $commit in mvn-site/" || echo "Nothing changed."
if $push; then
    git -C "$TREE" push -q -u "$REMOTE" gh-pages
fi
