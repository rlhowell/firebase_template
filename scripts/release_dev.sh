#!/usr/bin/env bash
# Run from Git Bash or WSL. Requires: ruby, bundler, fvm.
# First time: run `bundle install` from the project root.
set -euo pipefail
cd "$(dirname "$0")/.."
bundle exec fastlane android deploy_dev
