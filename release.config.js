module.export = {
  release: {
    branches: ["master"]
  },
  plugins: [
    [
      "@semantic-release/exec",
      {
        prepare: "npm run bump --version=${nextRelease.version}",
      }
    ],
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
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
