#!/usr/bin/env bats

load 'test-helper'

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

@test "should success with username" {
    _run_helm_git "git+https://git@github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=master"
    [ $status = 0 ]
}

@test "should success when sparse false" {
    _run_helm_git "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=master&sparse=0"
    [ $status = 0 ]
}

@test "should success when sparse true" {
    _run_helm_git "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=master&sparse=1"
    [ $status = 0 ]
}

@test "should success with forward slash in ref" {
    _run_helm_git "git+https://github.com/jaroslaw-osmanski/helm-git-test@test-chart/index.yaml?ref=feature/feature-test"
    [ $status = 0 ]
}
