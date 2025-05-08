#!/bin/bash
# Script to export your DAOOB project from Replit to GitHub
# Make sure you've already created a repository on GitHub

# Instructions:
# 1. Create a GitHub repository (as described in the README)
# 2. Replace the GITHUB_REPO_URL below with your repository URL
# 3. Run this script: bash export-to-github.sh

# Set your GitHub repository URL here
GITHUB_REPO_URL="https://github.com/yourusername/daoob-event-management.git"

echo "🚀 Preparing to export DAOOB project to GitHub"
echo "=============================================="
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install git first."
    exit 1
fi

# Check if the repository URL is set
if [ "$GITHUB_REPO_URL" = "https://github.com/yourusername/daoob-event-management.git" ]; then
    echo "⚠️ You haven't set your actual GitHub repository URL in this script."
    echo "Please edit this script and replace the GITHUB_REPO_URL variable with your repository URL."
    echo "For example: GITHUB_REPO_URL=\"https://github.com/johndoe/daoob-project.git\""
    exit 1
fi

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    echo "📦 Initializing git repository..."
    git init
    echo "✅ Git repository initialized"
else
    echo "📦 Git repository already initialized"
fi

# Add all files to git
echo "📦 Adding files to git..."
git add .

# Commit the changes
echo "📦 Committing changes..."
git commit -m "Initial commit of DAOOB Event Management Platform"
if [ $? -ne 0 ]; then
    echo "❌ Failed to commit. Please configure your git user information:"
    echo "git config --global user.email \"you@example.com\""
    echo "git config --global user.name \"Your Name\""
    exit 1
fi

# Add the remote repository
echo "📦 Adding remote repository..."
git remote add origin $GITHUB_REPO_URL
if [ $? -ne 0 ]; then
    # If the remote already exists, try to set the URL
    git remote set-url origin $GITHUB_REPO_URL
fi

# Push to GitHub
echo "📦 Pushing to GitHub..."
git push -u origin main

# Check if the push was successful
if [ $? -eq 0 ]; then
    echo "✅ Successfully pushed to GitHub!"
    echo "Your project is now available at: $GITHUB_REPO_URL"
else
    # Try pushing to master branch if main failed
    echo "⚠️ Pushing to main branch failed, trying master branch..."
    git push -u origin master
    
    if [ $? -eq 0 ]; then
        echo "✅ Successfully pushed to GitHub!"
        echo "Your project is now available at: $GITHUB_REPO_URL"
    else
        echo "❌ Failed to push to GitHub. Possible reasons:"
        echo "  - The repository URL is incorrect"
        echo "  - You don't have permission to push to this repository"
        echo "  - You need to authenticate with GitHub (try with HTTPS URL and your credentials)"
        echo ""
        echo "Alternative approach:"
        echo "1. Download your project from Replit (using the Download button)"
        echo "2. Extract the downloaded ZIP file on your local machine"
        echo "3. Run these commands in your local terminal:"
        echo "   cd path/to/extracted/folder"
        echo "   git init"
        echo "   git add ."
        echo "   git commit -m \"Initial commit\""
        echo "   git branch -M main"
        echo "   git remote add origin $GITHUB_REPO_URL"
        echo "   git push -u origin main"
    fi
fi