#!/usr/bin/env bash
# Run from Git Bash or WSL. Requires: ruby, bundler, fvm.
# First time: run `bundle install` from the project root.
set -euo pipefail
cd "$(dirname "$0")/.."

# Invoked via Gem.bin_path rather than `bundle exec fastlane`, which is not on
# PATH on Windows - bundler reports "command not found: fastlane" even with the
# gem installed.
bundle exec ruby -e "load Gem.bin_path('fastlane', 'fastlane')" -- android deploy_prod
