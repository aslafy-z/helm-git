#!/usr/bin/env bats

load 'test-helper'

parse_fun() {
  a=$1
}

@test "test fun" {
    parse_fun "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml"
    [ $a = "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml" ]
}

@test "test fun 2" {
    parse_fun "git+https://github.com/jetstack/cert-manager@2"
    [ $a = "git+https://github.com/jetstack/cert-manager@2" ]
}
