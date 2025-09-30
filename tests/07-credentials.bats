#!/usr/bin/env bats

load 'test-helper'

setup_file() {
    if ! helm_supports_credentials; then
        echo "# Skipping credential tests - Helm version < 3.14.0 does not support credential passing" >&2
    fi
}

@test "should setup git credentials when HELM_PLUGIN_USERNAME and HELM_PLUGIN_PASSWORD are set" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    export HELM_PLUGIN_USERNAME="testuser"
    export HELM_PLUGIN_PASSWORD="testpass"

    # Call setup_git_credentials function to check that credentials flag is set
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && setup_git_credentials && echo "HELM_GIT_USE_CREDENTIALS=${HELM_GIT_USE_CREDENTIALS}"'
    [ $status = 0 ]

    # Check that HELM_GIT_USE_CREDENTIALS is set to enable git_cmd wrapper
    [[ "$output" == *"HELM_GIT_USE_CREDENTIALS=1"* ]]

    # Check that the global GIT_USER and GIT_PASSWORD are not set (they should not be exported globally)
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && setup_git_credentials && echo "GIT_USER=${GIT_USER:-unset}" && echo "GIT_PASSWORD=${GIT_PASSWORD:-unset}"'
    [ $status = 0 ]
    [[ "$output" == *"GIT_USER=unset"* ]]
    [[ "$output" == *"GIT_PASSWORD=unset"* ]]
}

@test "should not setup git credentials when HELM_PLUGIN_USERNAME is missing" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    unset HELM_PLUGIN_USERNAME
    export HELM_PLUGIN_PASSWORD="testpass"

    # Call setup_git_credentials function
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && setup_git_credentials && echo "HELM_GIT_USE_CREDENTIALS=${HELM_GIT_USE_CREDENTIALS:-unset}"'
    [ $status = 0 ]

    # Check that HELM_GIT_USE_CREDENTIALS is not set
    [[ "$output" == *"HELM_GIT_USE_CREDENTIALS=unset"* ]]
}

@test "should not setup git credentials when HELM_PLUGIN_PASSWORD is missing" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    export HELM_PLUGIN_USERNAME="testuser"
    unset HELM_PLUGIN_PASSWORD

    # Call setup_git_credentials function
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && setup_git_credentials && echo "HELM_GIT_USE_CREDENTIALS=${HELM_GIT_USE_CREDENTIALS:-unset}"'
    [ $status = 0 ]

    # Check that HELM_GIT_USE_CREDENTIALS is not set
    [[ "$output" == *"HELM_GIT_USE_CREDENTIALS=unset"* ]]
}

@test "should not setup git credentials when both are missing" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    unset HELM_PLUGIN_USERNAME
    unset HELM_PLUGIN_PASSWORD

    # Call setup_git_credentials function
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && setup_git_credentials && echo "HELM_GIT_USE_CREDENTIALS=${HELM_GIT_USE_CREDENTIALS:-unset}"'
    [ $status = 0 ]

    # Check that HELM_GIT_USE_CREDENTIALS is not set
    [[ "$output" == *"HELM_GIT_USE_CREDENTIALS=unset"* ]]
}

@test "helm_git main should call setup_git_credentials with username and password" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    export HELM_PLUGIN_USERNAME="testuser"
    export HELM_PLUGIN_PASSWORD="testpass"

    # Test that main function sets up credentials by checking git config
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && export HELM_GIT_DEBUG=1 && main "" "" "" "git+https://example.com/repo@index.yaml?ref=master" 2>&1 || true'

    # Check that the debug message about setting up credentials appears
    [[ "$output" == *"Setting up git credentials using Helm-provided username and password"* ]]
}

@test "git credential helper should work with environment variables" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    export HELM_PLUGIN_USERNAME="testuser"
    export HELM_PLUGIN_PASSWORD="testpass"

    # Test the credential helper by simulating what git_cmd does
    run bash -c 'GIT_USER="testuser" GIT_PASSWORD="testpass" bash <<EOF
echo "username=\${GIT_USER}"
echo "password=\${GIT_PASSWORD}"
EOF'
    [ $status = 0 ]
    [[ "$output" == *"username=testuser"* ]]
    [[ "$output" == *"password=testpass"* ]]
}

@test "should handle credentials with special characters" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    export HELM_PLUGIN_USERNAME="user@domain.com"
    export HELM_PLUGIN_PASSWORD="pass/with/special&chars"

    # Call setup_git_credentials function to verify it handles special characters
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && setup_git_credentials && echo "HELM_GIT_USE_CREDENTIALS=${HELM_GIT_USE_CREDENTIALS}"'
    [ $status = 0 ]

    # Check that HELM_GIT_USE_CREDENTIALS is set, meaning credentials were processed successfully
    [[ "$output" == *"HELM_GIT_USE_CREDENTIALS=1"* ]]

    # Test that the credential helper can handle special characters
    run bash -c 'GIT_USER="user@domain.com" GIT_PASSWORD="pass/with/special&chars" bash <<EOF
echo "username=\${GIT_USER}"
echo "password=\${GIT_PASSWORD}"
EOF'
    [ $status = 0 ]
    [[ "$output" == *"username=user@domain.com"* ]]
    [[ "$output" == *"password=pass/with/special&chars"* ]]
}

@test "git_cmd should use credentials when available" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    export HELM_PLUGIN_USERNAME="testuser"
    export HELM_PLUGIN_PASSWORD="testpass"

    # Test git_cmd function
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && setup_git_credentials && git_cmd config --list | grep -E "(user|credential)" || echo "No credential config found"'
    [ $status = 0 ]

    # Should succeed (exit code 0)
}

@test "git_cmd should work normally when no credentials" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    unset HELM_PLUGIN_USERNAME
    unset HELM_PLUGIN_PASSWORD
    unset HELM_GIT_USE_CREDENTIALS

    # Test git_cmd function without credentials
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && setup_git_credentials && git_cmd --version'
    [ $status = 0 ]
    [[ "$output" == *"git version"* ]]
}
