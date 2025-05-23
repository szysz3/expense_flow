#!/bin/bash

generate_coverage_helper() {
    local package_name=$1
    local package_path="packages/$package_name"
    local test_file="$package_path/test/coverage_helper_test.dart"

    echo "Generating coverage helper for $package_name..."

    cat > "$test_file" << EOF
// Auto-generated coverage helper for $package_name package
// This ensures all source files are included in coverage calculation
// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';

EOF

    # Find all dart files and generate imports
    find "$package_path/lib" -name "*.dart" \
        -not -name "*.g.dart" \
        -not -name "*.freezed.dart" \
        -not -name "*.mocks.dart" \
        -not -path "*/generated/*" | \
    while read -r file; do
        # Convert file path to import statement
        import_path=$(echo "$file" | sed "s|$package_path/lib/|package:$package_name/|")
        echo "import '$import_path';" >> "$test_file"
    done

    cat >> "$test_file" << EOF

void main() {
  test('coverage helper - ensures all files are included', () {
    expect(true, true);
  });
}
EOF

    echo "Generated $test_file"
}

# Generate for each package
for package in domain data presentation; do
    if [ -d "packages/$package" ]; then
        generate_coverage_helper "$package"
    else
        echo "Package $package not found, skipping..."
    fi
done

echo ""
echo "✅ Coverage helpers generated!"
echo "📁 Files created:"
for package in domain data presentation; do
    if [ -f "packages/$package/test/coverage_helper_test.dart" ]; then
        echo "   - packages/$package/test/coverage_helper_test.dart"
    fi
done
echo ""
echo "🧪 Run 'melos run coverage' to see real coverage with all files included."