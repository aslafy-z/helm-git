#!/usr/bin/env bats

load 'test-helper'

@test "should success and warning with no ref" {
    parse_uri "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml"
    [ $git_repo = "https://github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
}

@test "should success and warning with empty ref" {
    parse_uri "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref="
    [ $git_repo = "https://github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
    [ $git_ref = "master" ]
}

@test "should success with username" {
    parse_uri "git+https://git@github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=master"
    [ $git_repo = "https://git@github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
    [ $git_ref = "master" ]
}

@test "should success when sparse false" {
    parse_uri "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=master&sparse=0"
    [ $git_repo = "https://git@github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
    [ $git_ref = "master" ]
    [ $git_sparse = "0" ]
}

@test "should success when sparse true" {
    parse_uri "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=master&sparse=1"
    [ $git_repo = "https://git@github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
    [ $git_ref = "master" ]
    [ $git_sparse = "1" ]
}

@test "should success with forward slash in ref" {
    parse_uri "git+https://github.com/jaroslaw-osmanski/helm-git-test@test-chart/index.yaml?ref=feature/feature-test"
    [ $git_repo = "https://github.com/jaroslaw-osmanski/helm-git-test" ]
    [ $helm_dir = "test-chart" ]
    [ $git_ref = "feature/feature-test" ]
}

@test "should success with leading forward slash in path" {
    parse_uri "git+https://github.com/jaroslaw-osmanski/helm-git-test@/test-chart/index.yaml?ref=feature/feature-test"
    [ $git_repo = "https://github.com/jaroslaw-osmanski/helm-git-test" ]
    [ $helm_dir = "/test-chart" ]
    [ $git_ref = "feature/feature-test" ]
}

@test "should success with empty git_path without slash" {
    parse_uri "git+https://github.com/hashicorp/vault-helm@index.yaml?ref=v0.5.0"
    [ $git_repo = "https://github.com/jaroslaw-osmanski/helm-git-test" ]
    [ $helm_dir = "" ]
    [ $git_ref = "v0.5.0" ]
}

@test "should success with empty git_path without slash" {
    parse_uri "git+https://github.com/hashicorp/vault-helm@/index.yaml?ref=v0.5.0"
    [ $git_repo = "https://github.com/jaroslaw-osmanski/helm-git-test" ]
    [ $helm_dir = "" ]
    [ $git_ref = "v0.5.0" ]
}

@test "should success with GitLab-style groups" {
    parse_uri "git+https://gitlab.com/gitlab-org/charts/gitlab@charts/gitlab/index.yaml?ref=master"
    [ $git_repo = "https://gitlab.com/gitlab-org/charts/gitlab" ]
    [ $helm_dir = "charts/gitlab" ]
    [ $git_ref = "master" ]
}
