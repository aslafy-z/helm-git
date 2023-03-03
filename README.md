# helm-git

![GitHub Actions](https://github.com/aslafy-z/helm-git/workflows/test/badge.svg?branch=master)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](./LICENSE)
[![GitHub release](https://img.shields.io/github/tag-date/aslafy-z/helm-git.svg)](https://github.com/aslafy-z/helm-git/releases)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

The Helm downloader plugin that provides GIT protocol support.

This fits multiple use cases:

- Need to keep charts private
- Doesn't want to package charts before installing
- Charts in a sub-path, or with another ref than `master`
- Pull values files directly from (private) Git repository

## Install

Use `helm` CLI to install this plugin:

    helm plugin install https://github.com/aslafy-z/helm-git --version 0.15.1

To use the plugin, you only need `git`. If you want to build the plugin from source, or you want to contribute
to the plugin, please see [these instructions](.github/CONTRIBUTING.md).

## Uninstall

    helm plugin remove helm-git

## Usage

`helm-git` will package any chart that is not so you can  directly reference paths to original charts.

Here's the Git urls format, followed by examples:

    git+https://[provider.com]/[user]/[repo]@[path/to/charts][?[ref=git-ref][&sparse=0][&depupdate=0]]
    git+ssh://git@[provider.com]/[user]/[repo]@[path/to/charts][?[ref=git-ref][&sparse=0][&depupdate=0]]
    git+file://[path/to/repo]@[path/to/charts][?[ref=git-ref][&sparse=0][&depupdate=0]]

    git+https://github.com/jetstack/cert-manager@deploy/charts?ref=v0.6.2&sparse=0
    git+ssh://git@github.com/jetstack/cert-manager@deploy/charts?ref=v0.6.2&sparse=1
    git+ssh://git@github.com/jetstack/cert-manager@deploy/charts?ref=v0.6.2
    git+https://github.com/istio/istio@install/kubernetes/helm?ref=1.5.4&sparse=0&depupdate=0
    git+https://github.com/bitnami/charts@bitnami/wordpress?depupdate=0?ref=master&sparse=0&depupdate=0&package=0

Add your repository:

    helm repo add cert-manager git+https://github.com/jetstack/cert-manager@deploy/charts?ref=v0.6.2

You can use it as any other Helm chart repository. Try:

    $ helm search repo cert-manager
    NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
    cert-manager/cert-manager               v0.6.6          v0.6.2          A Helm chart for cert-manager

    $ helm install cert-manager/cert-manager --version "0.6.6"

Fetching also works:

    helm fetch cert-manager/cert-manager --version "0.6.6"
    helm fetch git+https://github.com/jetstack/cert-manager@deploy/charts/cert-manager-v0.6.2.tgz?ref=v0.6.2

Pulling value files:

    helm install . -f git+https://github.com/aslafy-z/helm-git@tests/fixtures/example-chart/values.yaml

### Environment variables

**name**|**description**|**default**
--------|---------------|-----------
`HELM_GIT_HELM_BIN`|Path to the `helm` binary. If not set, `$HELM_BIN` will be used.|`helm`
`HELM_GIT_DEBUG`|Setting this value to `1` increases `helm-git` log level to the maximum. |`0`
`HELM_GIT_REPO_CACHE`|Path to use as a Git repository cache to avoid fetching repos more than once. If empty, caching of Git repositories is disabled.|`""`
`HELM_GIT_CHART_CACHE`|Path to use as a Helm chart cache to avoid re-packaging/re-indexing charts. If empty, caching of Helm charts is disabled.|`""`

### Arguments

**name**|**description**|**default**
--------|---------------|-----------
`ref`|Set git ref to a branch or tag. Also works for commits with `sparse=0`.|`master`
`sparse`|Set git strategy to sparse. Will try to fetch only the needed commits for the target path. If set to `0`, default git strategy will be used.|`1`
`depupdate`|Run `helm dependency update` on the retrieved chart. If set to `0`, this step is skipped.|`1`
`package`|Run `helm package` on the retrieved chart. If set to `0`, this step is skipped.|`1`

### Note on Git authentication

As this plugin uses `git` CLI to clone repos. You can configure private access in the same manner that with any `git` repo.

- **using ssh**: Start a [ssh-agent daemon](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#adding-your-ssh-key-to-the-ssh-agent)
- **using https**: Use a [credentials helper](https://git-scm.com/docs/gitcredentials)

### Note on SSH relative paths

Helm parses the input URL before passing it down to the Helm downloader plugins (which is the type of this `helm-git` plugin). It does so by using the `net/url.Parse` Golang method, which does not support the full IETF specification. Specifically, it does not support `:` as the first path separator like in `git+ssh://git@github.com:aslafy-z/helm-git` as Git supports it. This means that you'll have to use an absolute path instead by using the `/` separator as in `git+ssh://git@github.com/aslafy-z/helm-git`. This should not be an issue in most case as major hosts supports the use of absolute paths instead of relative ones.
If this becomes an issue for you, please open an issue and we may implement something to fill the gap until Golang or Helm does so.

## Troubleshooting

You can enable debug output by setting `HELM_GIT_DEBUG` environment variable to `1`:

    HELM_GIT_DEBUG=1 helm repo add cert-manager git+https://github.com/jetstack/cert-manager@deploy/charts?ref=v0.6.2

In order to debug in a more efficient maneer, I advise you use `helm fetch` instead of `helm repo add`.

## Contributing

Contributions are welcome! Please see [these instructions](.github/CONTRIBUTING.md) that will help you to develop the plugin.

## Alternatives

- <https://github.com/diwakar-s-maurya/helm-git>
- <https://github.com/sagansystems/helm-github>

## License

[MIT](LICENSE)
