# helm-git

[![CircleCI](https://circleci.com/gh/aslafy-z/helm-git/tree/master.svg?style=shield)](https://circleci.com/gh/aslafy-z/helm-git/tree/master)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](./LICENSE)
[![GitHub release](https://img.shields.io/github/tag-date/aslafy-z/helm-git.svg)](https://github.com/aslafy-z/helm-git/releases)

The Helm downloader plugin that provides GIT protocol support.

This fits multiple use cases:
- Need to keep charts private
- Doesn't want to package charts before installing
- Charts in a sub-path, or with another ref than `master`

## Install

The installation itself is simple as:

    $ helm plugin install https://github.com/aslafy-z/helm-git.git

You can install a specific release version:

    $ helm plugin install https://github.com/aslafy-z/helm-git.git --version 0.2.0

To use the plugin, you only need `git`. If you want to build the plugin from source, or you want to contribute
to the plugin, please see [these instructions](.github/CONTRIBUTING.md).

## Uninstall

    $ helm plugin remove helm-git

## Usage

`helm-git` will package any chart that is not so you can  directly reference paths to original charts.

Here's the Git urls format, followed by examples:

    git+https://[provider.com]/[user]/[repo]@[path/to/charts]?ref=[git-ref]
    git+ssh://git@[provider.com]/[user]/[repo]@[path/to/charts]?ref=[git-ref]

    git+https://github.com/jetstack/cert-manager@contrib/charts?ref=v0.5.2
    git+ssh://git@github.com/jetstack/cert-manager@contrib/charts?ref=v0.5.2

Add your repository:

    $ helm repo add cert-manager git+https://github.com/jetstack/cert-manager@contrib/charts?ref=v0.5.2

You can use it as any other Helm chart repository. Try:

    $ helm search coolcharts
    NAME                       	VERSION	  DESCRIPTION
    cert-manager/cert-manager   0.5.2     A Helm chart.


    $ helm install cert-manager/cert-manager --version "0.5.2"

Fetching also works:

    $ helm fetch cert-manager/cert-manager --version "0.5.2"
    $ helm fetch git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager-0.5.2.tgz?ref=v0.5.2

### Note on Git authentication

As this plugin uses `git` CLI to clone repos. You can configure private access in the same manner that with any `git` repo.

- **using ssh**: Start a [ssh-agent daemon](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#adding-your-ssh-key-to-the-ssh-agent)
- **using https**: Use a [credentials helper](https://git-scm.com/docs/gitcredentials)

## Contributing

Contributions are welcome! Please see [these instructions](.github/CONTRIBUTING.md) that will help you to develop the plugin.

## Alternatives

- https://github.com/diwakar-s-maurya/helm-git
- https://github.com/sagansystems/helm-github

## License

[MIT](LICENSE)
