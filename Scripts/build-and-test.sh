#!/bin/bash

set -e

echo "==> Showing Xcode version"
xcodebuild -version

echo "==> Showing Swift version"
swift --version

echo "==> Building project"
swift build -c release

echo "==> Running tests"
swift test 2>&1 | tee /tmp/test-output.txt

# Check if tests actually passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    # Extract and show test summary
    echo "✅ All tests passed!"
else
    echo ""
    echo "❌ Tests failed!"
    exit 1
fi
