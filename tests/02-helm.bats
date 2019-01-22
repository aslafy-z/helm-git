#!/usr/bin/env bats

load 'helm-git-helper'

# helm_init(helm_home)
@test "helm_init proprely initialize helm" {
    target_path=$(stashdir_new "test helm_init")
    run helm_init "$target_path"
    [ $status = 0 ]
    HELM_HOME=$target_path
    [ -d "$HELM_HOME/cache" ]
    [ -d "$HELM_HOME/plugins" ]
    [ -d "$HELM_HOME/repository" ]
    [ -d "$HELM_HOME/starters" ]
}

# helm_package(target_path, source_path, chart_name)
@test "helm_package proprely package example-chart" {
    target_path=$(stashdir_new "test helm_package")
    source_path="$BATS_TEST_DIRNAME/fixtures/example-chart"
    helm_args="--home=$HELM_HOME"
    run helm_package "$target_path" "$source_path" "example-chart"
    [ $status = 0 ]
    run stat "$target_path/example-chart-0.1.0.tgz"
    [ $status = 0 ]
}

# helm_package(target_path, source_path, chart_name)
@test "helm_package fails with incorrect chart" {
    target_path=$(stashdir_new "test helm_package")
    source_path="$BATS_TEST_DIRNAME/fixtures/existing-dir"
    run helm_package "$target_path" "$source_path" "existing-dir"
    [ $status = 1 ]
}

# helm_dependency_update(target_path)
@test "helm_dependency_update success with example-chart" {
    target_path=$(stashdir_new "test helm_package")
    cp -r "$BATS_TEST_DIRNAME/fixtures/example-chart" "$target_path"
    run helm_dependency_update "$target_path/example-chart"
    [ $status = 0 ]
}

# helm_dependency_update(target_path)
@test "helm_dependency_update fails with incorrect chart" {
    target_path=$(stashdir_new "test helm_package")
    cp -r "$BATS_TEST_DIRNAME/fixtures/existing-dir" "$target_path"
    run helm_dependency_update "$target_path/existing-dir"
    [ $status = 1 ]
}

# helm_inspect_name(source_path)
@test "helm_inspect_name success with example-chart" {
    source_path=$(stashdir_new "test helm_inspect_name")
    cp -r "$BATS_TEST_DIRNAME/fixtures/example-chart" "$source_path"
    output=$(helm_inspect_name "$source_path/example-chart" 2>/dev/null)
    [ $? = 0 ]
    [ "$output" == "example-chart" ]
}


# helm_inspect_name(source_path)
@test "helm_inspect_name fails with incorrect chart" {
    source_path=$(stashdir_new "test helm_inspect_name")
    cp -r "$BATS_TEST_DIRNAME/fixtures/existing-dir" "$source_path"
    run helm_inspect_name "$source_path/existing-dir"
    [ $status = 1 ]
}

# helm_index(target_path, base_url)
@test "helm_index success with example-chart" {
    target_path=$(stashdir_new "test helm_package")
    cp -r "$BATS_TEST_DIRNAME/fixtures/prebuilt-chart" "$target_path"
    base_url="htts://fake-url"
    run helm_index "$target_path/prebuilt-chart" "$base_url"
    [ $status = 0 ]
    run cat "$target_path/prebuilt-chart/index.yaml"
    [ $status = 0 ]
    [ -n "${output##*"entries: {}"*}" ]
}

# helm_index(target_path, base_url)
@test "helm_index fails with non-built chart" {
    target_path=$(stashdir_new "test helm_package")
    cp -r "$BATS_TEST_DIRNAME/fixtures/example-chart" "$target_path"
    base_url="htts://fake-url"
    run helm_index "$target_path/example-chart" "$base_url"
    [ $status = 0 ]
    run cat "$target_path/example-chart/index.yaml"
    [ $status = 0 ]
    [ -z "${output##*"entries: {}"*}" ]
}
