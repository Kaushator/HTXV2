#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Status Report Generator

This script generates a status report for the HTXEnterface_v2 project.
It collects information about recent commits, open issues, tests, and
code quality metrics.

Author: GitHub Copilot
Date: 2023-07-25
"""

import os
import sys
import json
import datetime
import subprocess
import requests
from jinja2 import Template

# Configuration
REPO_OWNER = "YOUR_GITHUB_USERNAME"  # Change this
REPO_NAME = "HTXEnterface_v2"  # Change this if needed
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
HEADERS = {"Authorization": f"token {GITHUB_TOKEN}"}

# HTML template for the report
TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HTXEnterface_v2 Status Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
        }
        h1, h2 {
            color: #0366d6;
        }
        .date {
            color: #586069;
            font-size: 0.9em;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid #dfe2e5;
        }
        th {
            background-color: #f6f8fa;
        }
        .success {
            color: #28a745;
        }
        .failure {
            color: #d73a49;
        }
        .warning {
            color: #f9c513;
        }
        .metrics {
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
        }
        .metric-card {
            width: 30%;
            background-color: #f6f8fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 15px;
        }
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>HTXEnterface_v2 Status Report</h1>
        <p class="date">Generated on {{ date }}</p>

        <h2>Repository Summary</h2>
        <div class="metrics">
            <div class="metric-card">
                <div>Commits (last 7 days)</div>
                <div class="metric-value">{{ commit_count }}</div>
            </div>
            <div class="metric-card">
                <div>Open Issues</div>
                <div class="metric-value">{{ open_issues }}</div>
            </div>
            <div class="metric-card">
                <div>Open PRs</div>
                <div class="metric-value">{{ open_prs }}</div>
            </div>
        </div>

        <h2>Recent Commits</h2>
        <table>
            <tr>
                <th>Author</th>
                <th>Message</th>
                <th>Date</th>
            </tr>
            {% for commit in recent_commits %}
            <tr>
                <td>{{ commit.author }}</td>
                <td>{{ commit.message }}</td>
                <td>{{ commit.date }}</td>
            </tr>
            {% endfor %}
        </table>

        <h2>Test Status</h2>
        <table>
            <tr>
                <th>Component</th>
                <th>Status</th>
                <th>Coverage</th>
            </tr>
            {% for test in test_status %}
            <tr>
                <td>{{ test.component }}</td>
                <td class="{{ test.status_class }}">{{ test.status }}</td>
                <td>{{ test.coverage }}</td>
            </tr>
            {% endfor %}
        </table>

        <h2>Code Quality</h2>
        <table>
            <tr>
                <th>Metric</th>
                <th>Value</th>
                <th>Status</th>
            </tr>
            {% for metric in code_quality %}
            <tr>
                <td>{{ metric.name }}</td>
                <td>{{ metric.value }}</td>
                <td class="{{ metric.status_class }}">{{ metric.status }}</td>
            </tr>
            {% endfor %}
        </table>
    </div>
</body>
</html>
"""

def get_github_data():
    """Retrieve data from GitHub API"""
    base_url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}"

    # Get repository information
    repo_response = requests.get(f"{base_url}", headers=HEADERS)
    if repo_response.status_code != 200:
        print(f"Error fetching repository data: {repo_response.status_code}")
        sys.exit(1)

    repo_data = repo_response.json()

    # Get commits from the last 7 days
    week_ago = (datetime.datetime.now() - datetime.timedelta(days=7)).strftime("%Y-%m-%d")
    commits_response = requests.get(
        f"{base_url}/commits?since={week_ago}",
        headers=HEADERS
    )

    if commits_response.status_code != 200:
        print(f"Error fetching commits: {commits_response.status_code}")
        sys.exit(1)

    commits_data = commits_response.json()

    # Get open issues
    issues_response = requests.get(
        f"{base_url}/issues?state=open&per_page=100",
        headers=HEADERS
    )

    if issues_response.status_code != 200:
        print(f"Error fetching issues: {issues_response.status_code}")
        sys.exit(1)

    issues_data = issues_response.json()

    # Get open pull requests
    prs_response = requests.get(
        f"{base_url}/pulls?state=open&per_page=100",
        headers=HEADERS
    )

    if prs_response.status_code != 200:
        print(f"Error fetching pull requests: {prs_response.status_code}")
        sys.exit(1)

    prs_data = prs_response.json()

    return {
        "repo": repo_data,
        "commits": commits_data,
        "issues": issues_data,
        "prs": prs_data
    }

def simulate_test_status():
    """
    Simulate test status data
    In a real implementation, you would collect this from your CI system
    """
    return [
        {
            "component": "Backend",
            "status": "Passing",
            "status_class": "success",
            "coverage": "87%"
        },
        {
            "component": "Frontend",
            "status": "Passing",
            "status_class": "success",
            "coverage": "79%"
        },
        {
            "component": "Integration Tests",
            "status": "1 Failing",
            "status_class": "warning",
            "coverage": "N/A"
        }
    ]

def simulate_code_quality():
    """
    Simulate code quality metrics
    In a real implementation, you would collect this from tools like SonarQube
    """
    return [
        {
            "name": "Code Smells",
            "value": "42",
            "status": "Good",
            "status_class": "success"
        },
        {
            "name": "Duplicated Code",
            "value": "3.2%",
            "status": "Good",
            "status_class": "success"
        },
        {
            "name": "Technical Debt",
            "value": "2.5 days",
            "status": "Warning",
            "status_class": "warning"
        }
    ]

def generate_report():
    """Generate the HTML status report"""
    github_data = get_github_data()

    # Format data for the report
    recent_commits = []
    for commit in github_data["commits"][:5]:  # Show 5 most recent commits
        commit_date = datetime.datetime.strptime(
            commit["commit"]["author"]["date"],
            "%Y-%m-%dT%H:%M:%SZ"
        ).strftime("%Y-%m-%d %H:%M")

        recent_commits.append({
            "author": commit["commit"]["author"]["name"],
            "message": commit["commit"]["message"].split("\n")[0],  # Just the first line
            "date": commit_date
        })

    # Count open issues that aren't PRs
    open_issues_count = len([i for i in github_data["issues"] if "pull_request" not in i])

    # Render the template
    template = Template(TEMPLATE)
    report = template.render(
        date=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        commit_count=len(github_data["commits"]),
        open_issues=open_issues_count,
        open_prs=len(github_data["prs"]),
        recent_commits=recent_commits,
        test_status=simulate_test_status(),
        code_quality=simulate_code_quality()
    )

    # Write the report to a file
    with open("status_report.html", "w", encoding="utf-8") as f:
        f.write(report)

    print("Report generated: status_report.html")

if __name__ == "__main__":
    # Ensure we have a token
    if not GITHUB_TOKEN:
        print("Error: GITHUB_TOKEN environment variable is required")
        sys.exit(1)

    generate_report()
