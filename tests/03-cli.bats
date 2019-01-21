load 'helm-git'

@test "fetch cert-manager/v0.5.2/index.yaml" {
    target_path=$(stashdir_new "cert-manager-v0.5.2")
    url="git+https://github.com/jetstack/cert-manager@v0.5.2/contrib/charts/cert-manager/index.yaml"
    $HELM_GIT_DIRNAME/helm-git "" "" "" "$url" 2>/dev/null > "$target_path/index.yaml"
    [ $? = 0 ]
    run stat "$target_path/index.yaml"
    [ $status = 0 ]
    [ -n "$(cat "$target_path/index.yaml" | grep -v 'entries: {}' | grep entries)" ]
}

@test "fetch cert-manager/v0.5.2/cert-manager-v0.5.2.tgz" {
    target_path=$(stashdir_new "cert-manager-v0.5.2")
    url="git+https://github.com/jetstack/cert-manager@v0.5.2/contrib/charts/cert-manager/cert-manager-v0.5.2.tgz"
    $HELM_GIT_DIRNAME/helm-git "" "" "" "$url" 2>/dev/null > "$target_path/cert-manager-v0.5.2.tgz"
    [ $? = 0 ]
    run stat "$target_path/cert-manager-v0.5.2.tgz"
    [ $status = 0 ]
}

