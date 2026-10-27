#!/bin/bash
# Publishes the demonstration on GitHub Pages of the fork, https://dashorst.github.io/maven-site/:
# builds with the base URL /maven-site and commits the result on the gh-pages branch, kept
# in the worktree .gh-pages/. The version built by `mvn site`, in mvn-site/, stays: that one
# is published from the doxia-demo branch by doxia/publish.sh.
#
# Usage: jekyll/publish.sh [--no-push]
set -euo pipefail
cd "$(dirname "$0")/.."
REMOTE=${REMOTE:-origin}
TREE=.gh-pages

jekyll/build.sh --baseurl /maven-site
commit=$(git rev-parse --short HEAD)

if [[ ! -d "$TREE" ]]; then
    if git ls-remote --exit-code --heads "$REMOTE" gh-pages >/dev/null; then
        git fetch -q "$REMOTE" gh-pages
        git worktree add -q -B gh-pages "$TREE" "$REMOTE/gh-pages"
    else
        git worktree add -q --orphan -b gh-pages "$TREE"
    fi
fi
find "$TREE" -mindepth 1 -maxdepth 1 ! -name .git ! -name mvn-site -exec rm -rf {} +
cp -a _site/. "$TREE"/
touch "$TREE/.nojekyll"
git -C "$TREE" add -A
git -C "$TREE" commit -q -m "Publish diataxis-demo at $commit" || echo "Nothing changed."
if [[ "${1:-}" != "--no-push" ]]; then
    git -C "$TREE" push -q -u "$REMOTE" gh-pages
fi
