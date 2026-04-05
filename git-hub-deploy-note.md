# Build the web app
flutter build web --wasm --base-href "/eddie-the-dev-frontend/"
# Deploy to gh-pages branch

- copy web folder to somewhere

## first time
git checkout --orphan github-page 

## future
git checkout github-page 

- delete all content
- paste content from recently copied web folder

git add .; git commit -m "deploy 1.0.6prod"; git push origin github-page --force; git checkout main;

