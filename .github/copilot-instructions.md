# helm-git Plugin Development
helm-git is a Helm downloader plugin that enables fetching charts directly from Git repositories. The plugin is written primarily in shell script with npm-based development tooling.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively
- Install development dependencies:
  - `npm install` -- takes ~20 seconds, downloads and sets up shellcheck
- Run linting (always do this before committing):
  - `npm run lint` -- takes <10 seconds. Uses editorconfig-checker and shellcheck
- Run tests:
  - `npm run test` -- takes ~62 seconds. NEVER CANCEL. Set timeout to 300+ seconds.
  - `npm run test:e2e` -- takes ~7 seconds. NEVER CANCEL. Set timeout to 60+ seconds.
- Test plugin functionality directly:
  - `HELM_BIN=helm ./helm-git "" "" "" "git+https://github.com/aslafy-z/helm-git@tests/fixtures/example-chart/index.yaml?ref=master"`
  - Should output valid Helm chart index.yaml content
- Test end-to-end with helm:
  - `helm plugin install .` to install plugin locally
  - `helm fetch git+https://github.com/aslafy-z/helm-git@tests/fixtures/example-chart/example-chart-0.1.0.tgz?ref=master` to test full workflow

## Prerequisites
- `helm` (any version - tested with 2.17.0, 3.4.2, 3.7.1)
- `git` (any recent version)
- Node.js >=20.11.1 (for development tooling only)
- Standard Unix utilities (sh, sed, grep, mktemp, etc.)

## Validation
- ALWAYS run `npm run lint` before committing changes - the CI will fail otherwise
- ALWAYS run `npm run test` after making changes to shell scripts - takes ~62 seconds, set timeout to 300+ seconds, NEVER CANCEL
- ALWAYS test plugin functionality with the direct command: `HELM_BIN=helm ./helm-git "" "" "" "git+https://github.com/aslafy-z/helm-git@tests/fixtures/example-chart/index.yaml?ref=master"`
- ALWAYS test end-to-end functionality: `helm fetch git+https://github.com/aslafy-z/helm-git@tests/fixtures/example-chart/example-chart-0.1.0.tgz?ref=master`
- Some tests may fail due to network connectivity issues (GitLab, charts.helm.sh repositories) - these are not blocking if core functionality works
- Plugin requires `HELM_BIN` environment variable for direct testing

## Common Tasks
The following are outputs from frequently run commands. Reference them instead of viewing, searching, or running bash commands to save time.

### Repository Structure
```
.
├── README.md               # Main documentation
├── plugin.yaml            # Helm plugin definition
├── helm-git               # Entry point script (wrapper)
├── helm-git-plugin.sh     # Main plugin logic (shell script)
├── package.json           # Development dependencies and scripts
├── tests/                 # BATS test suite
│   ├── test-helper.bash   # Test utilities
│   ├── 01-git.bats       # Git functionality tests
│   ├── 02-helm.bats      # Helm integration tests
│   ├── 03-cli.bats       # CLI tests
│   ├── 04-uri-parsing.bats # URI parsing tests
│   ├── 05-helm-cli.bats  # Helm CLI tests
│   ├── 06-helm-git-cache.bats # Caching tests
│   ├── e2e.bats          # End-to-end tests
│   └── fixtures/         # Test data
├── .github/
│   ├── workflows/        # CI/CD pipelines
│   └── CONTRIBUTING.md   # Development guidelines
└── .husky/               # Git hooks
```

### package.json scripts
```json
{
  "scripts": {
    "test": "bats --print-output-on-failure tests/*-*.bats",
    "test:e2e": "bats --print-output-on-failure tests/e2e.bats", 
    "lint": "editorconfig-checker; shellcheck 'helm-git' *.sh tests/*.bash"
  }
}
```

### plugin.yaml content
```yaml
name: "helm-git"
version: "1.4.0"
description: "Get non-packaged Charts directly from Git."
downloaders:
- command: "helm-git"
  protocols:
    - "git+file"
    - "git+ssh" 
    - "git+https"
    - "git+http"
```

## Plugin Architecture
- **Entry Point**: `helm-git` script - small wrapper that sources the main plugin
- **Main Logic**: `helm-git-plugin.sh` - contains all plugin functionality
- **Protocol Support**: git+https, git+ssh, git+file, git+http
- **Core Functions**:
  - `main()` - entry point called by Helm
  - `git_checkout()` - clones/fetches Git repositories  
  - `helm_package()` - packages charts with Helm
  - `helm_dependency_update()` - updates chart dependencies
  - `parse_uri()` - parses git+protocol URLs

## Environment Variables
- `HELM_GIT_DEBUG=1` - enable debug output
- `HELM_GIT_TRACE=1` - enable maximum logging and preserve temp dirs
- `HELM_GIT_HELM_BIN` - path to helm binary (defaults to `helm`)
- `HELM_GIT_REPO_CACHE` - path for git repository caching
- `HELM_GIT_CHART_CACHE` - path for helm chart caching

## Debugging
- Set `HELM_GIT_DEBUG=1` for basic debug output
- Set `HELM_GIT_TRACE=1` for verbose output and to preserve temporary directories
- Use `helm fetch` instead of `helm repo add` for more efficient debugging
- Direct plugin testing: `HELM_BIN=helm ./helm-git "" "" "" "git+<URL>"`

## CI/CD Pipeline 
- **Linting**: editorconfig-checker and shellcheck validation
- **Testing**: BATS test suite against multiple Helm versions (2.17.0, 3.4.2, 3.7.1)
- **Matrix Testing**: Tests run against different Helm versions in parallel
- **Release**: Automated semantic release when merged to master

## Development Notes
- No traditional build step required - it's a shell script plugin
- All development tooling is Node.js-based but the plugin itself has no Node.js runtime dependency
- Tests use BATS (Bash Automated Testing System)
- Some tests may fail in restricted network environments (normal and expected)
- Plugin supports both Helm v2 and v3 with version detection
- Supports chart caching and sparse git checkout for performance
