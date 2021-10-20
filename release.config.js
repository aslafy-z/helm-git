module.exports = {
  release: {
    branches: ["master"]
  },
  plugins: [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/exec",
      {
        prepareCmd: "npm run bump --version=${nextRelease.version}",
      }
    ],
    [
      "@semantic-release/git",
      {
        assets: [
          "package.json",
          "package-lock.json",
          "plugin.yaml",
          "README.md"
        ],
        message: "chore(release): update versions to ${nextRelease.version} [skip ci]"
      }
    ],
    "@semantic-release/github",
    [
      "@semantic-release/npm",
      {
        npmPublish: false,
      },
    ],
  ],
  preset: "conventionalcommits",
};
