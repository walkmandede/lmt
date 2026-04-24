# Build the web app
flutter build web --wasm --base-href "/lmt/"
# Deploy to gh-pages branch

- copy web folder to somewhere

## first time
git checkout --orphan github-page 

## future
git checkout github-page 

- delete all content
- paste content from recently copied web folder

git add .; git commit -m "deploy 1.1.1prod"; git push origin github-page --force; git checkout main;


# extract all codes
find lib -name "*.dart" -type f -exec cat {} + > all_current_code.txt
