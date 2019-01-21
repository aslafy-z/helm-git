load 'helm-git'

function helm_git() { run $HELM_GIT_DIRNAME/helm-git '' '' '' "$1"; }

@test "should fail with bad prefix" {
    helm_git "badprefix+https://github.com/jetstack/cert-manager@v0.5.2/contrib/charts/cert-manager/index.yaml"
    [ $status = 1 ]
}

@test "should fail with bad separator" {
    helm_git "git+https://github.com/jetstack/cert-manager#v0.5.2/contrib/charts/cert-manager/index.yaml"
    [ $status = 1 ]
}

@test "should fail with no separator" {
    helm_git "git+https://github.com/jetstack/cert-manager/v0.5.2/contrib/charts/cert-manager/index.yaml"
    [ $status = 1 ]
}

@test "should fail with bad protocol" {
    helm_git "git+unknown://github.com/jetstack/cert-manager@master/index.yaml"
    [ $status = 1 ]
}

@test "should fail with no protocol" {
    helm_git "git+git@github.com:toto/toto@master/index.yaml"
    [ $status = 1 ]
}

@test "should fail and warning with bad path and no ref" {
    helm_git "git+https://github.com/jetstack/cert-manager@/contrib/charts/cert-manager/index.yaml"
    [ $status = 1 ]
    [ -n "$(echo $output | grep "git_ref is empty")" ]
}

@test "should success and warning with no ref" {
    helm_git "git+https://github.com/jetstack/cert-manager@/deploy/charts/index.yaml"
    [ $status = 0 ]
    [ -n "$(echo $output | grep "git_ref is empty")" ]
}