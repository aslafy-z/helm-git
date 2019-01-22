# Contributing to helm-git plugin

## Development

`helm-git` is a little wrapper to be run by `helm`. If you want to do so, you'll have to call it as Helm does. See the doc for more precise informations: https://docs.helm.sh/using_helm/#downloader-plugins.

```
# command   certFile    keyFile caFile  full-URL
./helm-git  ""          ""      ""      "git+https://..."
```

Tooling deps are managed by `npm`. To install dev environment, run
```
npm install
```

## Tests

Run tests with 
```
npm run test
```

A special rule exists that includes `e2e` and transform output to be CI compatible (xUnit). See 

```
npm run
```
