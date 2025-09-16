#!/bin/bash
#
# Script: auto-pr.sh
# Description: Creates a PR for code changes automatically with AI-generated description
# Author: GitHub Copilot
# Date: 2023-07-25
#
# Usage: ./auto-pr.sh [--title "PR Title"] [--branch feature-branch]
#
# Requirements:
#   - Git CLI
#   - GitHub CLI (gh) with authentication
#   - curl for API calls

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

# Process command line arguments
PR_TITLE=""
PR_BRANCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --title)
            PR_TITLE="$2"
            shift 2
            ;;
        --branch)
            PR_BRANCH="$2"
            shift 2
            ;;
        *)
            print_error "Unknown argument: $1"
            echo "Usage: $0 [--title \"PR Title\"] [--branch feature-branch]"
            exit 1
            ;;
    esac
done

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install it first."
    exit 1
fi

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    print_error "GitHub CLI (gh) is not installed. Please install it first."
    print_info "Visit https://cli.github.com/ for installation instructions."
    exit 1
fi

# Check if user is authenticated with GitHub CLI
if ! gh auth status &> /dev/null; then
    print_error "Not authenticated with GitHub CLI. Please run 'gh auth login' first."
    exit 1
fi

# Get the project root directory
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo $(pwd))
cd "$PROJECT_ROOT"

# Get current branch if not specified
if [ -z "$PR_BRANCH" ]; then
    PR_BRANCH=$(git branch --show-current)
fi

print_info "Working with branch: $PR_BRANCH"

# Check if there are uncommitted changes
if ! git diff --quiet || ! git diff --staged --quiet; then
    print_warning "You have uncommitted changes."
    read -p "Would you like to commit them now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Ask for commit message if not provided
        if [ -z "$PR_TITLE" ]; then
            read -p "Enter commit message: " commit_message
        else
            commit_message="$PR_TITLE"
        fi

        git add .
        git commit -m "$commit_message"
        print_success "Changes committed."
    else
        print_error "Please commit your changes before creating a PR."
        exit 1
    fi
fi

# Push changes to remote
print_info "Pushing changes to remote..."
git push -u origin "$PR_BRANCH" || (print_error "Failed to push to remote." && exit 1)

# Generate AI summary of changes
print_info "Generating AI summary of changes..."

# Get the default branch
DEFAULT_BRANCH=$(git remote show origin | grep "HEAD branch" | cut -d ":" -f 2 | xargs)

# Get changed files
changed_files=$(git diff --name-only origin/"$DEFAULT_BRANCH"..."$PR_BRANCH")

# Generate PR description
PR_DESCRIPTION="## AI-Generated Summary\n\nThis PR includes changes to the following files:\n\n"

for file in $changed_files; do
    PR_DESCRIPTION+="- \`$file\`\n"
done

PR_DESCRIPTION+="\n\n## Commit Summary\n\n"

# Get commit messages since branching from default branch
commit_messages=$(git log origin/"$DEFAULT_BRANCH"..."$PR_BRANCH" --pretty=format:"- %s")
PR_DESCRIPTION+="$commit_messages\n\n"

PR_DESCRIPTION+="\n\n## Testing Instructions\n\nPlease verify the changes by:\n\n1. Pulling this branch\n2. Testing functionality related to changes\n3. Checking code quality\n\n"

# Create PR
if [ -z "$PR_TITLE" ]; then
    # Use the latest commit message as PR title
    PR_TITLE=$(git log -1 --pretty=%B | head -n 1)
fi

print_info "Creating PR with title: $PR_TITLE"
PR_URL=$(gh pr create --title "$PR_TITLE" --body "$PR_DESCRIPTION" --base "$DEFAULT_BRANCH" --head "$PR_BRANCH")

if [ $? -eq 0 ]; then
    print_success "PR created successfully!"
    print_info "PR URL: $PR_URL"

    # Open PR in browser
    gh pr view --web
else
    print_error "Failed to create PR."
    exit 1
fi

exit 0
