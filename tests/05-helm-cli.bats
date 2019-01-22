#!/usr/bin/env bats

load 'helm-git-helper'

function _run_helm_git() { run $HELM_GIT_DIRNAME/helm-git '' '' '' "$1"; }

@test "helm_cli fetch index.yaml" {
    export HELM_HOME=$(stashdir_new "helm_home")
    target_dir=$(stashdir_new "helm_cli fetch test")
    run helm_init "$HELM_HOME"
    run helm plugin install "$HELM_GIT_DIRNAME"
    run helm fetch -d "$target_dir" "git+https://github.com/jetstack/cert-manager@contrib/charts/index.yaml?ref=v0.5.2"
    run stat "$target_dir/index.yaml"
    [ $status = 0 ]
}

@test "helm_cli fetch cert-manager-v0.5.2.tgz" {
    export HELM_HOME=$(stashdir_new "helm_home")
    target_dir=$(stashdir_new "helm_cli fetch test")
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run helm plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run helm fetch -d "$target_dir" "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager-v0.5.2.tgz?ref=v0.5.2"
    [ $status = 0 ]
    run stat "$target_dir/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

@test "helm_cli fetch cert-manager-v0.5.2.tgz relative" {
    export HELM_HOME=$(stashdir_new "helm_home")
    target_dir=$(stashdir_new "helm_cli fetch test")
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run helm plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run helm repo add cert-manager-v0.5.2 "git+https://github.com/jetstack/cert-manager@contrib/charts?ref=v0.5.2"
    [ $status = 0 ]
    run helm fetch -d "$target_dir" "cert-manager-v0.5.2/cert-manager"
    [ $status = 0 ]
    run stat "$target_dir/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

@test "helm_cli repo_add cert-manager-v0.5.2 charts" {
    export HELM_HOME=$(stashdir_new "helm_home")
    target_dir=$(stashdir_new "helm_cli fetch test")
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run helm plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run helm repo add cert-manager-v0.5.2 "git+https://github.com/jetstack/cert-manager@contrib/charts?ref=v0.5.2"
    [ $status = 0 ]
    run grep cert-manager-v0.5.2 "$HELM_HOME/repository/repositories.yaml"
    [ -n "$output" ]
}

@test "helm_cli repo_add cert-manager-v0.5.2 direct" {
    export HELM_HOME=$(stashdir_new "helm_home")
    target_dir=$(stashdir_new "helm_cli fetch test")
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run helm plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run helm repo add cert-manager-v0.5.2 "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager?ref=v0.5.2"
    [ $status = 0 ]
    run grep cert-manager-v0.5.2 "$HELM_HOME/repository/repositories.yaml"
    [ -n "$output" ]
}
