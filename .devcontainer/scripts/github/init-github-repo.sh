#!/bin/bash
#
# Script: init-github-repo.sh
# Description: Initializes a GitHub repository for the HTXV2 project.
# Author: GitHub Copilot
# Date: 2023-07-25
#
# Usage: ./init-github-repo.sh [repository-name] [private]
#   repository-name: Optional name for the repository (default: HTXV2)
#   private: Optional flag for private repository (default: true)
#
# Requirements:
#   - Git CLI
#   - GitHub CLI (gh)
#   - User must be authenticated with GitHub CLI (run 'gh auth login' first)

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

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed. Please install it first."
    print_info "Visit https://cli.github.com/ for installation instructions."
    exit 1
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install it first."
    exit 1
fi

# Check if user is authenticated with GitHub CLI
if ! gh auth status &> /dev/null; then
    print_error "Not authenticated with GitHub CLI. Please run 'gh auth login' first."
    exit 1
fi

# Default values
REPO_NAME=${1:-"HTXV2"}
PRIVATE=${2:-"true"}
CURRENT_DIR=$(pwd)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo $CURRENT_DIR)

print_info "Repository name: $REPO_NAME"
print_info "Private repository: $PRIVATE"
print_info "Project root: $PROJECT_ROOT"

# Navigate to project root
cd "$PROJECT_ROOT"

# Check if git is already initialized
if [ ! -d ".git" ]; then
    print_info "Initializing Git repository..."
    git init
    print_success "Git repository initialized."
else
    print_info "Git repository already initialized."
fi

# Check if GitHub repository already exists
if gh repo view "$REPO_NAME" &> /dev/null; then
    print_warning "GitHub repository '$REPO_NAME' already exists."

    read -p "Do you want to proceed and use this repository? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Exiting script. No changes were made."
        exit 0
    fi
else
    # Create GitHub repository
    print_info "Creating GitHub repository '$REPO_NAME'..."
    if [ "$PRIVATE" = "true" ]; then
        gh repo create "$REPO_NAME" --private
    else
        gh repo create "$REPO_NAME" --public
    fi
    print_success "GitHub repository created."
fi

# Configure git remote
print_info "Configuring git remote..."
REMOTE_URL="$(gh repo view "$REPO_NAME" --json url -q .url)"

# Check if remote 'origin' exists
if git remote | grep -q '^origin$'; then
    git remote set-url origin "$REMOTE_URL"
else
    git remote add origin "$REMOTE_URL"
fi
print_success "Git remote configured to $REMOTE_URL"

# Create .gitignore file if it doesn't exist
if [ ! -f ".gitignore" ]; then
    print_info "Creating .gitignore file..."
    cat > .gitignore << 'EOL'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Node.js
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.next/
out/

# Database
*.db
*.sqlite
*.sqlite3

# VS Code
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

# Docker
.docker/
docker-volumes/

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# OS specific
.DS_Store
Thumbs.db
ehthumbs.db
Desktop.ini

# Environment
.env
.venv
venv/
ENV/

# Testing
coverage/
.coverage
htmlcov/
.pytest_cache/
EOL
    print_success ".gitignore file created."
else
    print_info ".gitignore file already exists."
fi

# Add GitHub Actions workflow for code quality
print_info "Creating GitHub Actions workflows..."
mkdir -p .github/workflows

# Create a workflow for Python backend
cat > .github/workflows/backend-checks.yml << 'EOL'
name: Backend Checks

on:
  push:
    branches: [ main, master, dev ]
    paths:
      - 'backend/**'
  pull_request:
    branches: [ main, master, dev ]
    paths:
      - 'backend/**'

jobs:
  lint-and-test:
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

      - name: Lint with ruff
        run: |
          pip install ruff
          ruff check backend

      - name: Format check with black
        run: |
          pip install black
          black --check backend

      - name: Test with pytest
        run: |
          cd backend
          pytest
EOL

# Create a workflow for Frontend
cat > .github/workflows/frontend-checks.yml << 'EOL'
name: Frontend Checks

on:
  push:
    branches: [ main, master, dev ]
    paths:
      - 'frontend/**'
  pull_request:
    branches: [ main, master, dev ]
    paths:
      - 'frontend/**'

jobs:
  lint-and-test:
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

      - name: Lint check
        run: |
          cd frontend
          npm run lint

      - name: Run tests
        run: |
          cd frontend
          npm test
EOL

print_success "GitHub Actions workflows created."

# Stage all files
print_info "Staging files for commit..."
git add .

# Commit changes
print_info "Committing changes..."
git commit -m "Initial commit for $REPO_NAME"
print_success "Changes committed."

# Push to GitHub
print_info "Pushing to GitHub..."
git push -u origin main || git push -u origin master

print_success "Repository setup complete! Your code is now on GitHub."
print_info "Repository URL: $REMOTE_URL"

# Open the repository in browser
print_info "Opening repository in browser..."
gh repo view --web

exit 0
