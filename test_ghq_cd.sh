#!/bin/bash

# Test script for ghq-cd function

set -e

# Source the ghq-utils.sh
source "$(dirname "$0")/ghq-utils.sh"

echo "=== Testing ghq-cd function ==="
echo

# Get GHQ_ROOT for comparison
GHQ_ROOT=$(ghq root)
echo "GHQ_ROOT: $GHQ_ROOT"
echo

# Test 1: No arguments (should go to GHQ_ROOT)
echo "Test 1: ghq-cd (no arguments)"
ghq-cd
current_dir=$(pwd)
if [ "$current_dir" = "$GHQ_ROOT" ]; then
    echo "✓ PASS: Changed to GHQ_ROOT ($current_dir)"
else
    echo "✗ FAIL: Expected $GHQ_ROOT, got $current_dir"
    exit 1
fi
echo

# Test 2: Repository name only
echo "Test 2: ghq-cd ghq-utils"
ghq-cd ghq-utils
current_dir=$(pwd)
expected_dir="$GHQ_ROOT/github.com/garaemon/ghq-utils"
if [ "$current_dir" = "$expected_dir" ]; then
    echo "✓ PASS: Changed to $current_dir"
else
    echo "✗ FAIL: Expected $expected_dir, got $current_dir"
    exit 1
fi
echo

# Test 3: Account name/repository name
echo "Test 3: ghq-cd garaemon/ghq-utils"
cd "$GHQ_ROOT"  # Reset to GHQ_ROOT first
ghq-cd garaemon/ghq-utils
current_dir=$(pwd)
expected_dir="$GHQ_ROOT/github.com/garaemon/ghq-utils"
if [ "$current_dir" = "$expected_dir" ]; then
    echo "✓ PASS: Changed to $current_dir"
else
    echo "✗ FAIL: Expected $expected_dir, got $current_dir"
    exit 1
fi
echo

# Test 4: Full path (hostname/account/repository)
echo "Test 4: ghq-cd github.com/garaemon/ghq-utils"
cd "$GHQ_ROOT"  # Reset to GHQ_ROOT first
ghq-cd github.com/garaemon/ghq-utils
current_dir=$(pwd)
expected_dir="$GHQ_ROOT/github.com/garaemon/ghq-utils"
if [ "$current_dir" = "$expected_dir" ]; then
    echo "✓ PASS: Changed to $current_dir"
else
    echo "✗ FAIL: Expected $expected_dir, got $current_dir"
    exit 1
fi
echo

# Test 5: Non-existent repository (should fail)
echo "Test 5: ghq-cd non-existent-repo (should fail)"
cd "$GHQ_ROOT"  # Reset to GHQ_ROOT first
if ghq-cd non-existent-repo 2>/dev/null; then
    echo "✗ FAIL: Should have failed for non-existent repository"
    exit 1
else
    echo "✓ PASS: Correctly failed for non-existent repository"
fi
echo

echo "=== All tests passed! ==="
