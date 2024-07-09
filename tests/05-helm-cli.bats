#!/usr/bin/env bats

load 'test-helper'

@test "helm_cli fetch index.yaml" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/index.yaml?ref=v0.5.2"
    [ $status = 0 ]
    run stat "$HELM_GIT_OUTPUT/index.yaml"
    [ $status = 0 ]
}

@test "helm_cli fetch cert-manager-v0.5.2.tgz" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager-v0.5.2.tgz?ref=v0.5.2"
    [ $status = 0 ]
    run stat "$HELM_GIT_OUTPUT/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

@test "helm_cli fetch cert-manager-v0.5.2.tgz relative" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" repo add cert-manager-v0.5.2 "git+https://github.com/jetstack/cert-manager@contrib/charts?ref=v0.5.2"
    [ $status = 0 ]
    run "$HELM_BIN" fetch -d "$HELM_GIT_OUTPUT" "cert-manager-v0.5.2/cert-manager"
    [ $status = 0 ]
    run stat "$HELM_GIT_OUTPUT/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

@test "helm_cli repo_add cert-manager-v0.5.2 charts" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" repo add cert-manager-v0.5.2 "git+https://github.com/jetstack/cert-manager@contrib/charts?ref=v0.5.2"
    [ $status = 0 ]
    run "$HELM_BIN" repo remove cert-manager-v0.5.2
    [ $status = 0 ]
}

@test "helm_cli repo_add cert-manager-v0.5.2 direct" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" repo add cert-manager-v0.5.2 "git+https://github.com/jetstack/cert-manager@contrib/charts/cert-manager?ref=v0.5.2"
    [ $status = 0 ]
    run "$HELM_BIN" repo remove cert-manager-v0.5.2
    [ $status = 0 ]
}

@test "helm_cli repo_add istio-1.5.4 depupdate=0" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" repo add istio-1.5.4 'git+https://github.com/istio/istio@install/kubernetes/helm?ref=1.5.4&sparse=0&depupdate=0'
    [ $status = 0 ]
    run grep istio-1.5.4 "$HELM_HOME/repository/repositories.yaml"
    [ -n "$output" ]
}

@test "helm_cli repo_add wp-781987fa4bb120f52cbd74cd61484bf45bfb5daa depupdate=0 package=0" {
    helm_v2 && skip
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" repo add wp-781987fa4bb120f52cbd74cd61484bf45bfb5daa 'git+https://github.com/bitnami/charts@bitnami/wordpress?ref=781987fa4bb120f52cbd74cd61484bf45bfb5daa&sparse=0&depupdate=0&package=0'
    [ $status = 0 ]
    run grep wp-781987fa4bb120f52cbd74cd61484bf45bfb5daa "$HELM_HOME/repository/repositories.yaml"
    [ -n "$output" ]
}

@test "helm_cli template example-chart with remote values" {
    run helm_init "$HELM_HOME"
    [ $status = 0 ]
    run "$HELM_BIN" plugin install "$HELM_GIT_DIRNAME"
    [ $status = 0 ]
    run "$HELM_BIN" template "${HELM_GIT_DIRNAME}/tests/fixtures/prebuilt-chart/example-chart-0.1.0.tgz" -f "git+${FIXTURES_GIT_REPO}@tests/fixtures/example-chart/extra-values.yaml?ref=${FIXTURES_GIT_REF}" --output-dir "$HELM_GIT_OUTPUT"
    [ $status = 0 ]
    run grep -q "replicas: 999" "$HELM_GIT_OUTPUT/example-chart/templates/deployment.yaml"
    [ $status = 0 ]
}
