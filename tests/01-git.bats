#!/usr/bin/env bats

load 'helm-git-helper'

# git_sparse_checkout(target_path, git_repo, git_ref, git_path)

@test "git_sparse_checkout fail with non-existing path" {
  target_path=$(stashdir_new "fake git dir")
  git_repo="https://github.com/aslafy-z/helm-git"
  git_ref="feat/full-refactor"
  git_path="tests/fixtures/non-existing-dir"
  run git_sparse_checkout "$target_path" "$git_repo" "$git_ref" "$git_path"
  run stat "$target_path/$git_path/non-existing-file"
  [ $status = 1 ]
}

@test "git_sparse_checkout succeed with existing path" {
  target_path=$(stashdir_new "fake git dir")
  git_repo="https://github.com/aslafy-z/helm-git"
  git_ref="feat/full-refactor"
  git_path="tests/fixtures/existing-dir"
  run git_sparse_checkout "$target_path" "$git_repo" "$git_ref" "$git_path"
  run stat "$target_path/$git_path/existing-file"
  [ $status = 0 ]
}
