#!/bin/bash
#
# Script: setup-github-actions.sh
# Description: Sets up GitHub Actions workflows for the HTXEnterface_v2 project.
# Author: GitHub Copilot
# Date: 2023-07-25
#
# Usage: ./setup-github-actions.sh
#
# Requirements:
#   - Git CLI
#   - GitHub CLI (gh) with authentication

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

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install it first."
    exit 1
fi

# Get the project root directory
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo $(pwd))
cd "$PROJECT_ROOT"

print_info "Setting up GitHub Actions workflows in $PROJECT_ROOT"

# Create GitHub workflows directory
mkdir -p .github/workflows

# Create a workflow for code optimization and error checking
print_info "Creating code optimization workflow..."
cat > .github/workflows/code-quality.yml << 'EOL'
name: Code Quality & Optimization

on:
  push:
    branches: [ main, master, dev ]
  pull_request:
    branches: [ main, master, dev ]
  workflow_dispatch:  # Allow manual triggering

jobs:
  optimize-backend:
    name: Backend Optimization
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r backend/requirements.txt
          pip install ruff black isort mypy

      - name: Run code optimization
        run: |
          # Format code with black
          black backend --exclude=venv

          # Sort imports
          isort backend --profile black

          # Fix auto-fixable issues with ruff
          ruff check backend --fix

      - name: Commit changes
        uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: "🤖 Auto-optimize backend code"
          file_pattern: backend/**/*.py

  optimize-frontend:
    name: Frontend Optimization
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: 'frontend/package-lock.json'

      - name: Install dependencies
        run: |
          cd frontend
          npm ci

      - name: Run code optimization
        run: |
          cd frontend
          # Fix ESLint issues automatically where possible
          npm run lint -- --fix

          # Format code with Prettier
          npm run format

      - name: Commit changes
        uses: stefanzweifel/git-auto-commit-action@v4
        with:
          commit_message: "🤖 Auto-optimize frontend code"
          file_pattern: frontend/**/*.{js,jsx,ts,tsx,json,css,scss}

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
EOL

# Create dependabot configuration
print_info "Creating Dependabot configuration..."
mkdir -p .github
cat > .github/dependabot.yml << 'EOL'
version: 2
updates:
  # Backend Python dependencies
  - package-ecosystem: "pip"
    directory: "/backend"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "python"
    commit-message:
      prefix: "📦"

  # Frontend NPM dependencies
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    labels:
      - "dependencies"
      - "javascript"
    commit-message:
      prefix: "📦"

  # GitHub Actions
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "monthly"
    labels:
      - "dependencies"
      - "github_actions"
    commit-message:
      prefix: "👷"
EOL

# Create PR template
print_info "Creating PR template..."
mkdir -p .github/PULL_REQUEST_TEMPLATE
cat > .github/PULL_REQUEST_TEMPLATE/default.md << 'EOL'
## Description
<!--- Describe your changes in detail -->

## Related Issue
<!--- If fixing a bug, there should be an issue describing it with steps to reproduce -->
<!--- Please link to the issue here: -->

## Motivation and Context
<!--- Why is this change required? What problem does it solve? -->

## How Has This Been Tested?
<!--- Please describe in detail how you tested your changes. -->
<!--- Include details of your testing environment, and the tests you ran to -->
<!--- see how your change affects other areas of the code, etc. -->

## Screenshots (if appropriate):

## Types of changes
<!--- What types of changes does your code introduce? Put an `x` in all the boxes that apply: -->
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update
- [ ] Performance improvement

## Checklist:
<!--- Go over all the following points, and put an `x` in all the boxes that apply. -->
<!--- If you're unsure about any of these, don't hesitate to ask. We're here to help! -->
- [ ] My code follows the code style of this project.
- [ ] My change requires a change to the documentation.
- [ ] I have updated the documentation accordingly.
- [ ] I have added tests to cover my changes.
- [ ] All new and existing tests passed.
EOL

# Create Issue templates
print_info "Creating Issue templates..."
mkdir -p .github/ISSUE_TEMPLATE
cat > .github/ISSUE_TEMPLATE/bug_report.md << 'EOL'
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment (please complete the following information):**
 - OS: [e.g. Windows, macOS, Linux]
 - Browser [e.g. Chrome, Safari]
 - Version [e.g. 22]

**Additional context**
Add any other context about the problem here.
EOL

cat > .github/ISSUE_TEMPLATE/feature_request.md << 'EOL'
---
name: Feature request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
EOL

# Create codeowners file
print_info "Creating CODEOWNERS file..."
cat > .github/CODEOWNERS << 'EOL'
# These owners will be the default owners for everything in the repo.
* @project-admin

# Backend code
/backend/ @backend-team

# Frontend code
/frontend/ @frontend-team

# Infrastructure and DevOps
/infra/ @devops-team
docker-compose.yml @devops-team
Dockerfile* @devops-team

# Documentation
/docs/ @docs-team
*.md @docs-team
EOL

# Stage all files
print_info "Staging files for commit..."
git add .github

# Commit changes if there are any
if git diff-index --quiet HEAD; then
    print_info "No changes to commit."
else
    print_info "Committing changes..."
    git commit -m "Add GitHub Actions workflows and templates"
    print_success "Changes committed."
fi

print_success "GitHub Actions setup complete!"
print_info "To push these changes to GitHub, run: git push"

exit 0
