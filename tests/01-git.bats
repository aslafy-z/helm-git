#!/usr/bin/env bats

load 'test-helper'

# git_checkout(git_sparse, target_path, git_repo, git_ref, git_path)

@test "git_checkout fail with non-existing path" {
  git_sparse=1
  git_repo="https://github.com/aslafy-z/helm-git"
  git_ref="master"
  git_path="tests/fixtures/non-existing-dir"
  run git_checkout "$git_sparse" "$HELM_GIT_OUTPUT" "$git_repo" "$git_ref" "$git_path"
  [ $status = 1 ]
}

@test "git_checkout fail with non-existing ref" {
  git_sparse=1
  git_repo="https://github.com/aslafy-z/helm-git"
  git_ref="this/ref/wont/ever/exist"
  git_path="tests/fixtures/existing-dir"
  run git_checkout "$git_sparse" "$HELM_GIT_OUTPUT" "$git_repo" "$git_ref" "$git_path"
  [ $status = 1 ]
}

@test "git_checkout succeed with existing path" {
  git_sparse=1
  git_repo="https://github.com/aslafy-z/helm-git"
  git_ref="master"
  git_path="tests/fixtures/existing-dir"
  run git_checkout "$git_sparse" "$HELM_GIT_OUTPUT" "$git_repo" "$git_ref" "$git_path"
  [ $status = 0 ]
  run stat "$HELM_GIT_OUTPUT/$git_path/existing-file"
  [ $status = 0 ]
}

@test "git_checkout succeed with existing path and annotated tag" {
  git_sparse=1
  git_repo="https://github.com/aslafy-z/helm-git"
  git_ref="test-annotated-tag"
  git_path="tests/fixtures/existing-dir"
  run git_checkout "$git_sparse" "$HELM_GIT_OUTPUT" "$git_repo" "$git_ref" "$git_path"
  [ $status = 0 ]
  run stat "$HELM_GIT_OUTPUT/$git_path/existing-file"
  [ $status = 0 ]
}
