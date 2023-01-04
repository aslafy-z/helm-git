#!/usr/bin/env bats

load 'test-helper'

@test "fetch cert-manager/v0.5.2/index.yaml" {
    run helm_init "$HELM_HOME"
    url="git+file:///home/zadkiel/work/helm-git@tests/fixtures/example-chart-symlink/index.yaml?ref=fix/symlinks"
    $HELM_GIT_DIRNAME/helm-git "" "" "" "$url" > "$HELM_GIT_OUTPUT/index.yaml"
    [ $? = 0 ]
    run stat "$HELM_GIT_OUTPUT/index.yaml"
    [ $status = 0 ]
    [ -n "$(cat "$HELM_GIT_OUTPUT/index.yaml" | grep -v 'entries: {}' | grep entries)" ]
}
