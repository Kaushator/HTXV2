#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');

// Get current version from package.json
const packageJson = JSON.parse(fs.readFileSync('frontend/package.json', 'utf8'));
const currentVersion = packageJson.version;

// Parse version type from command line args
const versionType = process.argv[2] || 'patch'; // patch, minor, major

console.log(`Current version: ${currentVersion}`);

// Increment version
const versionParts = currentVersion.split('.').map(Number);
switch (versionType) {
  case 'major':
    versionParts[0]++;
    versionParts[1] = 0;
    versionParts[2] = 0;
    break;
  case 'minor':
    versionParts[1]++;
    versionParts[2] = 0;
    break;
  case 'patch':
  default:
    versionParts[2]++;
    break;
}

const newVersion = versionParts.join('.');
const tag = `v${newVersion}`;

console.log(`New version: ${newVersion}`);

// Update package.json
packageJson.version = newVersion;
fs.writeFileSync('frontend/package.json', JSON.stringify(packageJson, null, 2) + '\n');

// Update backend version
const pyprojectPath = 'backend/pyproject.toml';
if (fs.existsSync(pyprojectPath)) {
  let pyproject = fs.readFileSync(pyprojectPath, 'utf8');
  pyproject = pyproject.replace(/version = "[^"]*"/, `version = "${newVersion}"`);
  fs.writeFileSync(pyprojectPath, pyproject);
}

// Commit and tag
try {
  execSync('git add .');
  execSync(`git commit -m "chore: bump version to ${newVersion}"`);
  execSync(`git tag ${tag}`);
  
  console.log(`Created tag: ${tag}`);
  console.log('Push with: git push && git push --tags');
  console.log('Or trigger release workflow manually in GitHub Actions');
} catch (error) {
  console.error('Error creating tag:', error.message);
}
