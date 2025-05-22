#!/bin/bash

# Exit script if any command fails
set -e

echo "🧹 Cleaning up previous generated files..."
rm -rf .dart_tool/flutter_gen/gen_l10n
rm -rf lib/gen_l10n
mkdir -p lib/gen_l10n

echo "🌍 Generating localization files..."
flutter gen-l10n