#!/usr/bin/env sh

# See Helm plugins documentation: https://docs.helm.sh/using_helm/#downloader-plugins

# shellcheck disable=SC2039
set -e -o pipefail

readonly bin_name="helm-git"
readonly allowed_protocols="https http file ssh"
readonly url_prefix="git+"

readonly error_invalid_prefix="Git url should start with '$url_prefix'. Please check helm-git usage."
readonly error_invalid_protocol="Protocol not allowed, it should match one of theses: $allowed_protocols."

debug=0
if [ "$HELM_GIT_DEBUG" = "1" ]; then
  debug=1
fi

## Tooling

string_starts() { [ "$(echo "$1" | cut -c 1-${#2})" = "$2" ]; }
string_ends() { [ "$(echo "$1" | cut -c $((${#1}-${#2}+1))-${#1})" = "$2" ]; }
string_contains() { echo "$1" | grep -q "$2"; }
path_join() { echo "${1:+$1/}$2" | sed 's#//#/#g'; }

## Logging

debug() {
  [ $debug = 1 ] && echo "Debug in plugin '$bin_name': $*" >&2
  return 0
}

error() {
  echo "Error in plugin '$bin_name': $*" >&2
  exit 1
}

warning() {
  echo "Warning in plugin '$bin_name': $*" >&2
}

## Temporary folders

export TMPDIR=${TMPDIR:-/tmp}

# stashdir_init()
stashdir_init() {
  readonly stashdir_list_file=$(mktemp "$TMPDIR/helm-git.stash.XXXXXX")
  stashdir_clean_skip=$debug

  if [ $debug = 0 ]; then
    trap stashdir_clean EXIT
  fi
}

# stashdir_new(comment)
stashdir_new() {
  _comment="$1"

  new_dir=$(mktemp -d "$TMPDIR/helm-git.XXXXXX")
  echo "$new_dir" >> "$stashdir_list_file"
  echo "$new_dir"
  debug "stashdir_new<$_comment> = $new_dir"
}

# stashdir_clean()
stashdir_clean() {
  [ "$stashdir_clean_skip" -eq "1" ] && return 0
  xargs rm -rf < "$stashdir_list_file" >&2
  rm -f "$stashdir_list_file" >&2
}

## Functions

# git_try(git_repo)
git_try() {
  _git_repo=$1

  GIT_TERMINAL_PROMPT=0 git ls-remote "$_git_repo" --refs >&2 || return 1
}

# git_checkout(sparse, target_path, git_repo, git_ref, git_path)
git_checkout() {
  _sparse=$1
  _target_path=$2
  _git_repo=$3
  _git_ref=$4
  _git_path=$5

  cd "$_target_path" >&2
  git init --quiet
  git remote add origin "$_git_repo" >&2
  if [ "$_sparse" = "1" ]; then
    git config core.sparseCheckout true
    [ -n "$_git_path" ] && echo "$_git_path/*" > .git/info/sparse-checkout
    git pull --depth 1 origin "$_git_ref" 2>/dev/null 1>&2 || error \
      error "Unable to sparse-checkout. Check your git_ref and git_path."
  else
    git pull origin master 2>/dev/null 1>&2 || error \
      error "Unable to checkout. Check your git_ref and git_path."
    git checkout "$git_ref" >&2
  fi
}

# helm_init(helm_home)
helm_init() {
  _helm_home=$1
  helm init --client-only --home "$_helm_home" >/dev/null
  HELM_HOME=$_helm_home
  export HELM_HOME
}

# helm_package(target_path, source_path, chart_name)
helm_package() {
  _target_path=$1
  _source_path=$2
  _chart_name=$3

  tmp_target=$(stashdir_new "helm_package '$_source_path'")
  cp -r "$_source_path" "$tmp_target/$_chart_name"
  _source_path="$tmp_target/$_chart_name"
  cd "$_target_path" >&2

  # shellcheck disable=SC2086
  helm package $helm_args --save=false "$_source_path" >/dev/null
}

# helm_dependency_update(target_path)
helm_dependency_update() {
  _target_path=$1

  # shellcheck disable=SC2086
  helm dependency update $helm_args --skip-refresh "$_target_path" >/dev/null
}

# helm_index(target_path, base_url)
helm_index() {
  _target_path=$1
  _base_url=$2

  # shellcheck disable=SC2086
  helm repo index $helm_args --url="$_base_url" "$_target_path" >/dev/null
}

# helm_inspect_name(source_path)
helm_inspect_name() {
  _source_path=$1

  # shellcheck disable=SC2086
  output=$(helm inspect chart $helm_args "$_source_path")
  name=$(echo "$output" | grep -e '^name: ' | cut -d' ' -f2)
  echo "$name"
  [ -n "$name" ]
}

# main(raw_uri)
main() {
  helm_args="" # "$1 $2 $3"
  _raw_uri=$4 # eg: git+https://git.com/user/repo@path/to/charts/index.yaml?ref=master

  string_starts "$_raw_uri" "$url_prefix" || \
    error "Invalid format, got '$_raw_uri'. $error_invalid_prefix"

  _raw_uri=$(echo "$_raw_uri" | sed 's/^git+//')

  readonly git_proto=$(echo "$_raw_uri" | cut -d':' -f1)
  string_contains "$allowed_protocols" "$git_proto" || \
    error "$error_invalid_protocol"

  readonly git_repo=$(echo "$_raw_uri" | sed -E 's#^([^@\?]+)@?[^@\?]+\??.*$#\1#')
  # TODO: Validate git_repo
  readonly git_path=$(echo "$_raw_uri" | sed -E 's#.*@(.*)\/.*#\1#')
  # TODO: Validate git_path
  readonly helm_file=$(echo "$_raw_uri" | sed -E 's#.*@.*\/([^?]*).*#\1#')

  git_ref=$(echo "$_raw_uri" | sed '/^.*ref=\([^&#]*\).*$/!d;s//\1/')
  # TODO: Validate git_ref
  if [ -z "$git_ref" ]; then
    warning "git_ref is empty, defaulted to 'master'. Prefer to pin git_ref in URI."
    git_ref="master"
  fi

  git_sparse=$(echo "$_raw_uri" | sed '/^.*sparse=\([^&#]*\).*$/!d;s//\1/')
  [ -z "$git_sparse" ] && git_sparse=1

  debug "repo: $git_repo ref: $git_ref path: $git_path file: $helm_file sparse: $git_sparse"
  readonly helm_repo_uri="git+$git_repo@$git_path?ref=$git_ref&sparse=$git_sparse"
  debug "helm_repo_uri: $helm_repo_uri"

  stashdir_init

  readonly git_root_path=$(stashdir_new "git_root_path")
  readonly git_sub_path=$(path_join "$git_root_path" "$git_path")
  git_checkout "$git_sparse" "$git_root_path" "$git_repo" "$git_ref" "$git_path" || \
    error "Error while git_sparse_checkout"

  readonly helm_target_path=$(stashdir_new "helm_target_path")
  readonly helm_target_file="$(path_join "$helm_target_path" "$helm_file")"

  # Set helm home
  helm_home=$(helm home)
  if [ -z "$helm_home" ]; then
    readonly helm_home_target_path=$(stashdir_new "helm home")
    helm_init "$helm_home_target_path" || error "Couldn't init helm"
    helm_home=$helm_home_target_path
  fi
  helm_args="$helm_args --home=$helm_home"

  chart_search_root="$git_sub_path"

  chart_search=$(find "$chart_search_root" -maxdepth 2 -name "Chart.yaml" -print)
  chart_search_count=$(echo "$chart_search" | wc -l)

  echo "$chart_search" | {
    while IFS='' read -r chart_yaml_file; do
      chart_path=$(dirname "$chart_yaml_file")
      chart_name=$(helm_inspect_name "$chart_path")

      helm_dependency_update "$chart_path" || \
        error "Error while helm_dependency_update"
      helm_package "$helm_target_path" "$chart_path" "$chart_name" || \
        error "Error while helm_package"
    done
  }

  [ "$chart_search_count" -eq "0" ] && \
    error "No charts have been found"

  helm_index "$helm_target_path" "$helm_repo_uri" || \
    error "Error while helm_index"

  cat "$helm_target_file"
}
