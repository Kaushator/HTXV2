#!/bin/bash
#
# Script: github-actions-test.sh
# Description: Tests the GitHub Actions workflows for the HTXV2 project locally.
# Author: GitHub Copilot
# Date: 2023-07-25
#
# Usage: ./github-actions-test.sh
#
# Requirements:
#   - act tool (https://github.com/nektos/act)
#   - Docker
#   - GitHub Actions workflow files in .github/workflows/

set -e  # Exit immediately if a command exits with a non-zero status

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored messages
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if act is installed
if ! command -v act &> /dev/null; then
    print_error "'act' is not installed. You need it to test GitHub Actions locally."
    print_info "Install instructions: https://github.com/nektos/act#installation"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Get the project root directory
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo $(pwd))
cd "$PROJECT_ROOT"

# Check if workflows directory exists
if [ ! -d ".github/workflows" ]; then
    print_error "No GitHub Actions workflows found in .github/workflows/"
    print_info "Run setup-github-actions.sh first to create workflows."
    exit 1
fi

# List available workflows
print_info "Available GitHub Actions workflows:"
ls -1 .github/workflows/ | grep -E '\.ya?ml$' | sed 's/\.ya?ml$//'

# Ask which workflow to test
echo
echo "Which workflow would you like to test? (Enter filename without extension)"
read -p "> " workflow_name

# Check if the workflow exists
if [ ! -f ".github/workflows/${workflow_name}.yml" ] && [ ! -f ".github/workflows/${workflow_name}.yaml" ]; then
    print_error "Workflow '${workflow_name}' not found."
    exit 1
fi

# Get the file extension
workflow_ext="yml"
if [ -f ".github/workflows/${workflow_name}.yaml" ]; then
    workflow_ext="yaml"
fi

# Ask which event to trigger
echo
echo "Which event would you like to trigger? (push, pull_request, workflow_dispatch)"
read -p "> " event_name

# Run the workflow
print_info "Testing workflow '${workflow_name}' with event '${event_name}'..."
act ${event_name} -W .github/workflows/${workflow_name}.${workflow_ext} -v

# Check result
if [ $? -eq 0 ]; then
    print_success "Workflow test completed successfully!"
else
    print_error "Workflow test failed with errors."
    print_info "Check the output above for details."
fi

exit 0
