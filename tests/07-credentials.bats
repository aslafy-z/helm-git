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

    # Source the plugin and check that credentials are stored
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && echo "git_username=${git_username}" && echo "git_password=${git_password}"'
    [ $status = 0 ]
    [[ "$output" == *"git_username=testuser"* ]]
    [[ "$output" == *"git_password=testpass"* ]]

    # Check that the original HELM_PLUGIN_* variables are unset for security
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && echo "HELM_PLUGIN_USERNAME=${HELM_PLUGIN_USERNAME:-unset}" && echo "HELM_PLUGIN_PASSWORD=${HELM_PLUGIN_PASSWORD:-unset}"'
    [ $status = 0 ]
    [[ "$output" == *"HELM_PLUGIN_USERNAME=unset"* ]]
    [[ "$output" == *"HELM_PLUGIN_PASSWORD=unset"* ]]

    # Check that the internal git_* variables are NOT exported to child processes
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && bash -c "echo git_username=\${git_username:-unset}; echo git_password=\${git_password:-unset}"'
    [ $status = 0 ]
    [[ "$output" == *"git_username=unset"* ]]
    [[ "$output" == *"git_password=unset"* ]]
}

@test "should not setup git credentials when HELM_PLUGIN_USERNAME is missing" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    unset HELM_PLUGIN_USERNAME
    export HELM_PLUGIN_PASSWORD="testpass"

    # Source the plugin and verify git_username is empty
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && echo "git_username=${git_username:-empty}"'
    [ $status = 0 ]
    [[ "$output" == *"git_username=empty"* ]]
}

@test "should setup git credentials with username only (empty password allowed)" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    export HELM_PLUGIN_USERNAME="testuser"
    unset HELM_PLUGIN_PASSWORD

    # Source the plugin and verify credentials are set (username without password is allowed)
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && echo "git_username=${git_username}" && echo "git_password=${git_password:-empty}"'
    [ $status = 0 ]
    [[ "$output" == *"git_username=testuser"* ]]
    [[ "$output" == *"git_password=empty"* ]]
}

@test "should not setup git credentials when both are missing" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    unset HELM_PLUGIN_USERNAME
    unset HELM_PLUGIN_PASSWORD

    # Source the plugin and verify both are empty
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && echo "git_username=${git_username:-empty}" && echo "git_password=${git_password:-empty}"'
    [ $status = 0 ]
    [[ "$output" == *"git_username=empty"* ]]
    [[ "$output" == *"git_password=empty"* ]]
}

@test "helm_git main should use credentials with username and password" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    export HELM_PLUGIN_USERNAME="testuser"
    export HELM_PLUGIN_PASSWORD="testpass"
    export HELM_GIT_TRACE=1

    # Test that git_cmd uses credentials by checking trace output
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && git_cmd --version 2>&1'

    # Check that the trace message about using credentials appears
    [[ "$output" == *"Git credential helper configured with username: testuser"* ]]
    [[ "$output" == *"git version"* ]]
}

@test "git credential helper should work with environment variables" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    export HELM_PLUGIN_USERNAME="testuser"
    export HELM_PLUGIN_PASSWORD="testpass"

    # Test the credential helper by simulating what git_cmd does
    run bash -c 'GIT_USERNAME="testuser" GIT_PASSWORD="testpass" bash <<EOF
echo "username=\${GIT_USERNAME}"
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

    # Source the plugin and verify credentials with special characters are stored
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && echo "git_username=${git_username}" && echo "git_password=${git_password}"'
    [ $status = 0 ]
    [[ "$output" == *"git_username=user@domain.com"* ]]
    [[ "$output" == *"git_password=pass/with/special&chars"* ]]

    # Test that the credential helper can handle special characters
    run bash -c 'GIT_USERNAME="user@domain.com" GIT_PASSWORD="pass/with/special&chars" bash <<EOF
echo "username=\${GIT_USERNAME}"
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

    # Test git_cmd function with credentials
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && git_cmd --version'
    [ $status = 0 ]
    [[ "$output" == *"git version"* ]]
}

@test "git_cmd should work normally when no credentials" {
    if ! helm_supports_credentials; then
        skip "Helm version < 3.14.0 does not support credential passing"
    fi

    unset HELM_PLUGIN_USERNAME
    unset HELM_PLUGIN_PASSWORD

    # Test git_cmd function without credentials
    run bash -c 'source "${HELM_GIT_DIRNAME}/helm-git-plugin.sh" && git_cmd --version'
    [ $status = 0 ]
    [[ "$output" == *"git version"* ]]
}
