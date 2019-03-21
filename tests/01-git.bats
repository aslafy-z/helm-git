#!/usr/bin/env bats

load 'helm-git-helper'

# git_checkout(target_path, git_repo, git_ref, git_path)

@test "git_checkout fail with non-existing path" {
  target_path=$(stashdir_new "fake git dir")
  git_sparse=1
  git_repo="https://github.com/aslafy-z/helm-git"
  git_ref="master"
  git_path="tests/fixtures/non-existing-dir"
  run git_checkout "$git_sparse" "$target_path" "$git_repo" "$git_ref" "$git_path"
  [ $status = 1 ]
}

@test "git_checkout fail with non-existing ref" {
  target_path=$(stashdir_new "fake git dir")
  git_sparse=1
  git_repo="https://github.com/aslafy-z/helm-git"
  git_ref="this/ref/wont/ever/exist"
  git_path="tests/fixtures/existing-dir"
  run git_checkout "$git_sparse" "$target_path" "$git_repo" "$git_ref" "$git_path"
  [ $status = 1 ]
}

@test "git_checkout succeed with existing path" {
  target_path=$(stashdir_new "fake git dir")
  git_sparse=1
  git_repo="https://github.com/aslafy-z/helm-git"
  git_ref="master"
  git_path="tests/fixtures/existing-dir"
  run git_checkout "$git_sparse" "$target_path" "$git_repo" "$git_ref" "$git_path"
  [ $status = 0 ]
  run stat "$target_path/$git_path/existing-file"
  [ $status = 0 ]
}
