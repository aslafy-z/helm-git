#!/usr/bin/env bats

load 'helm-git-helper'

function _run_helm_git() { run $HELM_GIT_DIRNAME/helm-git '' '' '' "$1"; }

@test "should fail with bad prefix" {
    _run_helm_git "badprefix+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager/index.yaml?ref=v0.5.2"
    [ $status = 1 ]
}

@test "should fail with bad separator" {
    _run_helm_git "git+https://github.com/jetstack/cert-manager#contrib/charts/cert-manager/index.yaml?ref=v0.5.2"
    [ $status = 1 ]
}

@test "should fail with no separator" {
    _run_helm_git "git+https://github.com/jetstack/cert-manager/contrib/charts/cert-manager/index.yaml?ref=v0.5.2"
    [ $status = 1 ]
}

@test "should fail with bad protocol" {
    _run_helm_git "git+unknown://github.com/jetstack/cert-manager@index.yaml?ref=master"
    [ $status = 1 ]
}

@test "should fail with no protocol" {
    _run_helm_git "git+git@github.com:toto/toto@index.yaml?ref=master"
    [ $status = 1 ]
}

@test "should fail and warning with bad path and no ref" {
    _run_helm_git "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager/index.yaml?ref="
    [ $status = 1 ]
    [ -n "$(echo $output | grep "git_ref is empty")" ]
}

@test "should success and warning with no ref" {
    _run_helm_git "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml"
    [ $status = 0 ]
    [ -n "$(echo $output | grep "git_ref is empty")" ]
}
