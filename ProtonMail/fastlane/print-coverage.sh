#!/bin/bash

# Parses coverage file and prints out overall code coverage

TOTAL_XCTEST_COVERAGE=`xcrun xccov view --report $1 | grep '.app' | head -1 | perl -pe 's/.+?(\d+\.\d+%).+/\1/'`
echo "Total test coverage: $TOTAL_XCTEST_COVERAGE"
