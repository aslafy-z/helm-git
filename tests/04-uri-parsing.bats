#!/usr/bin/env bats

load 'test-helper'

@test "should parse with no options" {
    parse_uri "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml"
    [ $git_repo = "https://github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
}

@test "should parse with empty ref" {
    parse_uri "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref="
    [ $git_repo = "https://github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
    [ $git_ref = "master" ]
}

@test "should parse with ref" {
    parse_uri "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=foo"
    [ $git_repo = "https://github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
    [ $git_ref = "foo" ]
}

@test "should parse with username" {
    parse_uri "git+https://git@github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=master"
    [ $git_repo = "https://git@github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
    [ $git_ref = "master" ]
}

@test "should parse with sparse disabled" {
    parse_uri "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=master&sparse=0"
    [ $git_repo = "https://git@github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
    [ $git_ref = "master" ]
    [ $git_sparse = 0 ]
}

@test "should parse with sparse enabled" {
    parse_uri "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml?ref=master&sparse=1"
    [ $git_repo = "https://git@github.com/jetstack/cert-manager" ]
    [ $helm_dir = "deploy/charts" ]
    [ $git_ref = "master" ]
    [ $git_sparse = 1 ]
}

@test "should parse with forward slash in ref" {
    parse_uri "git+https://github.com/jaroslaw-osmanski/helm-git-test@test-chart/index.yaml?ref=feature/feature-test"
    [ $git_repo = "https://github.com/jaroslaw-osmanski/helm-git-test" ]
    [ $helm_dir = "test-chart" ]
    [ $git_ref = "feature/feature-test" ]
}

@test "should parse with leading forward slash in path" {
    parse_uri "git+https://github.com/jaroslaw-osmanski/helm-git-test@/test-chart/index.yaml?ref=feature/feature-test"
    [ $git_repo = "https://github.com/jaroslaw-osmanski/helm-git-test" ]
    [ $helm_dir = "/test-chart" ]
    [ $git_ref = "feature/feature-test" ]
}

@test "should parse with empty path without slash" {
    parse_uri "git+https://github.com/hashicorp/vault-helm@index.yaml?ref=v0.5.0"
    echo "$git_repo // $helm_dir // $git_ref"
    [ $git_repo = "https://github.com/jaroslaw-osmanski/helm-git-test" ]
    [ $helm_dir = "" ]
    [ $git_ref = "v0.5.0" ]
}

@test "should parse with empty path with slash" {
    parse_uri "git+https://github.com/hashicorp/vault-helm@/index.yaml?ref=v0.5.0"
    echo "$git_repo // $helm_dir // $git_ref"
    [ $git_repo = "https://github.com/jaroslaw-osmanski/helm-git-test" ]
    [ $helm_dir = "" ]
    [ $git_ref = "v0.5.0" ]
}

@test "should parse GitLab-style multi-level repos" {
    parse_uri "git+https://gitlab.com/gitlab-org/charts/gitlab@charts/gitlab/index.yaml?ref=master"
    [ $git_repo = "https://gitlab.com/gitlab-org/charts/gitlab" ]
    [ $helm_dir = "charts/gitlab" ]
    [ $git_ref = "master" ]
}
