#!/usr/bin/env bats

load 'test-helper'

parse_fun() {
  a=1
  b=2
}

@test "test fun" {
    parse_fun "git+https://github.com/jetstack/cert-manager@deploy/charts/index.yaml"
    [ $a = 1 ]
}
