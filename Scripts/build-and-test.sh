#!/bin/bash

set -e

echo "==> Showing Xcode version"
xcodebuild -version

echo "==> Showing Swift version"
swift --version

echo "==> Building project"
swift build -c release

echo "==> Running tests"
swift test --parallel

echo "✅ All tests passed!"
