#!/bin/bash

set -e

echo "==> Showing Xcode version"
xcodebuild -version

echo "==> Showing Swift version"
swift --version

echo "==> Building project using xcodebuild"
xcodebuild build -scheme DVR-iOS -configuration Release -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16'

echo "==> Running tests using xcodebuild"
xcodebuild test -scheme DVR-iOS -configuration Debug -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' 2>&1 | tee /tmp/test-output.txt

# Check if tests actually passed
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    # Extract and show test summary
    echo "✅ All tests passed!"
else
    echo ""
    echo "❌ Tests failed!"
    exit 1
fi
