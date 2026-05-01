#!/bin/bash

set -e

echo "Starting Flutter web build and deployment..."

# Step 1: Build Flutter web with WASM
echo ""
echo "Step 1: Building Flutter web with WASM..."
flutter build web --wasm --base-href "/lmt/"
echo "Build completed successfully!"

# Step 2: Copy build/web folder to Desktop
echo ""
echo "Step 2: Copying build/web to Desktop..."
rm -rf ~/Desktop/web
cp -r build/web ~/Desktop/web
echo "Copied to ~/Desktop/web"

# Step 3: Checkout github-page branch
echo ""
echo "Step 3: Checking out github-page branch..."
git checkout github-page
echo "Switched to github-page branch"

# Step 4: Delete all files and paste content from Desktop/web
echo ""
echo "Step 4: Replacing content with build files..."
find . -maxdepth 1 -not -name '.git' -not -name '.gitignore' -not -name '.' -exec rm -rf {} +
cp -r ~/Desktop/web/* .
echo "Content replaced"

# Step 5: Git add, commit, push, and switch back to main
echo ""
echo "Step 5: Committing and pushing to github-page..."
git add .
git commit -m "deploy to prod"
git push origin github-page --force
echo "Pushed to github-page"

echo ""
echo "Step 6: Switching back to main branch..."
git checkout main
echo "Switched to main branch"

echo ""
echo "Deployment completed successfully!"