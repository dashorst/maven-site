#!/bin/bash
# Builds the site into _site/: renders the Velocity templates on the host (Java), then runs
# Jekyll in the maven-site-jekyll container, which mounts this repository at /site.
#
# Usage: jekyll/build.sh [extra jekyll options, e.g. --baseurl /maven-site]
set -euo pipefail
cd "$(dirname "$0")/.."
CONTAINER=${CONTAINER:-maven-site-jekyll}
jekyll/velocity/render.sh >/dev/null
podman exec "$CONTAINER" bash -lc "
    set -e
    cd /site
    export BUNDLE_GEMFILE=/site/jekyll/Gemfile BUNDLE_PATH=/site/jekyll/.bundle-cache
    bundle install --quiet
    bundle exec jekyll build --source . --destination _site --config jekyll/_config.yml $*
"
