#!/usr/bin/env bats

load 'test-helper'

@test "fetch cert-manager/v0.5.2/index.yaml" {
    run helm_init "$HELM_HOME"
    url="git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager/index.yaml?ref=v0.5.2"
    $HELM_GIT_DIRNAME/helm-git "" "" "" "$url" 2>/dev/null > "$HELM_GIT_OUTPUT/index.yaml"
    [ $? = 0 ]
    run stat "$HELM_GIT_OUTPUT/index.yaml"
    [ $status = 0 ]
    [ -n "$(cat "$HELM_GIT_OUTPUT/index.yaml" | grep -v 'entries: {}' | grep entries)" ]
}

@test "fetch cert-manager/v0.5.2/cert-manager-v0.5.2.tgz" {
    run helm_init "$HELM_HOME"
    url="git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager/cert-manager-v0.5.2.tgz?ref=v0.5.2"
    $HELM_GIT_DIRNAME/helm-git "" "" "" "$url" 2>/dev/null > "$HELM_GIT_OUTPUT/cert-manager-v0.5.2.tgz"
    [ $? = 0 ]
    run stat "$HELM_GIT_OUTPUT/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}
