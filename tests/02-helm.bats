#!/usr/bin/env bats

load 'test-helper'

# helm_init(helm_home)
@test "helm_init properly initialize helm2" {
    helm_v2 || skip
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    [ -d "$HELM_HOME/cache" ]
    [ -d "$HELM_HOME/plugins" ]
    [ -d "$HELM_HOME/repository" ]
    [ -d "$HELM_HOME/starters" ]
}

# helm_package(target_path, source_path, chart_name)
@test "helm_package properly package example-chart" {
    source_path="$BATS_TEST_DIRNAME/fixtures/example-chart"
    helm_v2 && helm_args="--home=$HELM_HOME"
    run helm_package "$HELM_GIT_OUTPUT" "$source_path" "example-chart"
    [ $status = 0 ]
    run stat "$HELM_GIT_OUTPUT/example-chart-0.1.0.tgz"
    [ $status = 0 ]
}

# helm_package(target_path, source_path, chart_name)
@test "helm_package properly package example-chart-symlink" {
    source_path="$BATS_TEST_DIRNAME/fixtures/example-chart-symlink/chart"
    helm_v2 && helm_args="--home=$HELM_HOME"
    run helm_package "$HELM_GIT_OUTPUT" "$source_path" "example-chart-symlink"
    [ $status = 0 ]
    run stat "$HELM_GIT_OUTPUT/example-chart-symlink-0.1.0.tgz"
    [ $status = 0 ]
    run tar --strip-components=2 -C $HELM_GIT_OUTPUT -xf "$HELM_GIT_OUTPUT/example-chart-symlink-0.1.0.tgz" example-chart-symlink/crds/test.yaml
    [ $status = 0 ]
    run diff $source_path/crds/test.yaml $HELM_GIT_OUTPUT/test.yaml
}

# helm_package(target_path, source_path, chart_name)
@test "helm_package fails with incorrect chart" {
    source_path="$BATS_TEST_DIRNAME/fixtures/existing-dir"
    helm_args="--home=$HELM_HOME"
    run helm_package "$HELM_GIT_OUTPUT" "$source_path" "existing-dir"
    [ $status = 1 ]
}

# helm_dependency_update(target_path)
@test "helm_dependency_update success with example-chart" {
    cp -r "$BATS_TEST_DIRNAME/fixtures/example-chart" "$HELM_GIT_OUTPUT"
    run helm_dependency_update "$HELM_GIT_OUTPUT/example-chart"
    [ $status = 0 ]
}

# helm_dependency_update(target_path)
@test "helm_dependency_update fails with incorrect chart" {
    cp -r "$BATS_TEST_DIRNAME/fixtures/existing-dir" "$HELM_GIT_OUTPUT"
    run helm_dependency_update "$HELM_GIT_OUTPUT/existing-dir"
    [ $status = 1 ]
}

# helm_inspect_name(source_path)
@test "helm_inspect_name success with example-chart" {
    cp -r "$BATS_TEST_DIRNAME/fixtures/example-chart" "$HELM_GIT_OUTPUT"
    output=$(helm_inspect_name "$HELM_GIT_OUTPUT/example-chart" 2>/dev/null)
    [ $? = 0 ]
    [ "$output" == "example-chart" ]
}


# helm_inspect_name(source_path)
@test "helm_inspect_name fails with incorrect chart" {
    cp -r "$BATS_TEST_DIRNAME/fixtures/existing-dir" "$HELM_GIT_OUTPUT"
    run helm_inspect_name "$HELM_GIT_OUTPUT/existing-dir"
    [ $status = 1 ]
}

# helm_index(target_path, base_url)
@test "helm_index success with example-chart" {
    cp -r "$BATS_TEST_DIRNAME/fixtures/prebuilt-chart" "$HELM_GIT_OUTPUT"
    base_url="htts://fake-url"
    run helm_index "$HELM_GIT_OUTPUT/prebuilt-chart" "$base_url"
    [ $status = 0 ]
    run cat "$HELM_GIT_OUTPUT/prebuilt-chart/index.yaml"
    [ $status = 0 ]
    [ -n "${output##*"entries: {}"*}" ]
}

# helm_index(target_path, base_url)
@test "helm_index fails with non-built chart" {
    cp -r "$BATS_TEST_DIRNAME/fixtures/example-chart" "$HELM_GIT_OUTPUT"
    base_url="htts://fake-url"
    run helm_index "$HELM_GIT_OUTPUT/example-chart" "$base_url"
    [ $status = 0 ]
    run cat "$HELM_GIT_OUTPUT/example-chart/index.yaml"
    [ $status = 0 ]
    [ -z "${output##*"entries: {}"*}" ]
}
