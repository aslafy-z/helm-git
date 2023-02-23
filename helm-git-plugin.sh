#!/usr/bin/env sh

# See Helm plugins documentation: https://docs.helm.sh/using_helm/#downloader-plugins

set -eu

readonly bin_name="helm-git"
readonly allowed_protocols="https http file ssh"
readonly url_prefix="git+"

readonly error_invalid_prefix="Git url should start with '$url_prefix'. Please check helm-git usage."
readonly error_invalid_protocol="Protocol not allowed, it should match one of theses: $allowed_protocols."

debug=0
if [ "${HELM_GIT_DEBUG:-}" = "1" ]; then
  debug=1
fi

export TMPDIR="${TMPDIR:-/tmp}"

# Cache repos or charts depending on the cache path existing in the environment variables
CACHE_REPOS=$([ -n "${HELM_GIT_REPO_CACHE:-}" ] && echo "true" || echo "false")
CACHE_CHARTS=$([ -n "${HELM_GIT_CHART_CACHE:-}" ] && echo "true" || echo "false")

## Tooling

string_starts() { [ "$(echo "$1" | cut -c 1-${#2})" = "$2" ]; }
string_ends() { [ "$(echo "$1" | cut -c $((${#1} - ${#2} + 1))-${#1})" = "$2" ]; }
string_contains() { echo "$1" | grep -q "$2"; }
path_join() { echo "${1:+$1/}$2" | sed 's#//#/#g'; }

## Logging

debug() {
  [ $debug = 1 ] && echo "Debug[$$] in plugin '$bin_name': $*" >&2
  return 0
}

error() {
  echo "Error in plugin '$bin_name': $*" >&2
  exit 1
}

warning() {
  echo "Warning in plugin '$bin_name': $*" >&2
}

## Functions

# git_try(git_repo)
git_try() {
  _git_repo=$1

  GIT_TERMINAL_PROMPT=0 git ls-remote "$_git_repo" --refs >&2 || return 1
}

#git_cache_intercept(git_repo, git_ref)
git_cache_intercept() {
    _git_repo="${1?Missing git_repo as first parameter}"
    _git_ref="${2?Missing git_ref as second parameter}"
    debug "Trying to intercept for ${_git_repo}#${_git_ref}"
    repo_tokens=$(echo "${_git_repo}" | sed -E -e 's/[^/]+\/\/([^@]*@)?([^/]+)\/(.+)$/\2 \3/' -e 's/\.git$//g' )
    repo_host=$(echo "${repo_tokens}" | cut -d " " -f1)
    repo_repo=$(echo "${repo_tokens}" | cut -d " " -f2)
    if [ ! -d "${HELM_GIT_REPO_CACHE}" ]; then
        debug "HELM_GIT_REPO_CACHE:${HELM_GIT_REPO_CACHE} is not a directory, cannot cache"
        echo "${_git_repo}"
        return
    fi

    repo_path="${HELM_GIT_REPO_CACHE}/${repo_host}/${repo_repo}"
    debug "Calculated cache path for repo ${_git_repo} is ${repo_path}"

    if [ ! -d "${repo_path}" ]; then
        debug "First time I see ${_git_repo}, fetching into ${repo_path}"
        if ! git clone --bare --branch "${_git_ref}" "${_git_repo}" "${repo_path}" 2> /dev/null; then
            debug "Could not clone ${_git_repo}"
        fi
    else
        debug "${_git_repo} exists in cache"
    fi
    debug "Making sure we have the requested ref #${_git_ref}"
    if ! GIT_REPO="${repo_path}" git tag -l "${_git_ref}" >/dev/null 2>&1; then
        debug "Did not find ${_git_ref} in our cache for ${_git_repo}, fetching...."
        git fetch origin --quiet "${_git_ref}"
    else
        debug "Ref ${_git_ref} was already cached for ${_git_repo}"
    fi

    new_git_repo="file://${repo_path}"
    debug "Returning cached repo at ${new_git_repo}"
    echo "${new_git_repo}"
}

# git_checkout(sparse, target_path, git_repo, git_ref, git_path)
git_checkout() {
  _sparse=$1
  _target_path=$2
  _git_repo=$3
  _git_ref=$4
  _git_path=$5

  if $CACHE_REPOS; then
      _git_repo=$(git_cache_intercept "${_git_repo}" "${_git_ref}")
  fi

  cd "$_target_path" >&2
  git init --quiet
  git config pull.ff only
  git remote add origin "$_git_repo" >&2
  if [ "$_sparse" = "1" ]; then
    git config core.sparseCheckout true
    [ -n "$_git_path" ] && echo "$_git_path/*" >.git/info/sparse-checkout
    git pull --quiet --depth 1 origin "$_git_ref" >&2 || \
      error "Unable to sparse-checkout. Check your Git ref ($_git_ref) and path ($_git_path)."
  else
    git fetch --quiet --tags origin >&2 || \
      error "Unable to fetch remote. Check your Git url."
    git checkout --quiet "$git_ref" >&2 || \
      error "Unable to checkout ref. Check your Git ref ($git_ref)."
  fi
  # shellcheck disable=SC2010,SC2012
  if [ "$(ls -A | grep -v '^.git$' -c)" = "0" ]; then
    error "No files have been checked out. Check your Git ref ($_git_ref) and path ($_git_path)."
  fi
}

# helm_v2()
helm_v2() {
  "$HELM_BIN" version -c --short | grep -q v2
}

# helm_init(helm_home)
helm_init() {
  if ! helm_v2; then return 0; fi
  _helm_home=$1
  "$HELM_BIN" init --client-only --stable-repo-url https://charts.helm.sh/stable --home "$_helm_home" >/dev/null
  HELM_HOME=$_helm_home
  export HELM_HOME
}

# helm_package(target_path, source_path, chart_name)
helm_package() {
  _target_path=${1?First parameter should be the target path}
  _source_path=${2?Second parameter should be the source path}
  _chart_name=${3?Third parameter should be the chart name}

  # Ensure exists at least empty
  helm_args=${helm_args:-}

  tmp_target="$(mktemp -d "$TMPDIR/helm-git.XXXXXX")"
  cp -r "$_source_path" "$tmp_target/$_chart_name"
  _source_path="$tmp_target/$_chart_name"
  cd "$_target_path" >&2

  package_args=$helm_args
  helm_v2 && package_args="$package_args --save=false"
  # shellcheck disable=SC2086
  "$HELM_BIN" package $package_args "$_source_path" >/dev/null
  ret=$?

  rm -rf "$tmp_target"

  # forward return code
  return $ret
}

# helm_dependency_update(target_path)
helm_dependency_update() {
  _target_path=${1?First argument should be the target path}

  # Ensure exists at least empty
  helm_args=${helm_args:-}

  # Prevent infinity loop when calling helm-git plugin
  if ${HELM_GIT_DEPENDENCY_CIRCUITBREAKER:-false};  then
    # shellcheck disable=SC2086
    "$HELM_BIN" dependency update $helm_args --skip-refresh "$_target_path" >/dev/null
    ret=$?
  else
    export HELM_GIT_DEPENDENCY_CIRCUITBREAKER=true
    # shellcheck disable=SC2086
    "$HELM_BIN" dependency update $helm_args "$_target_path" >/dev/null
    ret=$?
  fi

  # forward return code
  return $ret
}

# helm_index(target_path, base_url)
helm_index() {
  _target_path=$1
  _base_url=$2

  # Ensure exists at least empty
  helm_args=${helm_args:-}

  # shellcheck disable=SC2086
  "$HELM_BIN" repo index $helm_args --url="$_base_url" "$_target_path" >/dev/null
}

# helm_inspect_name(source_path)
helm_inspect_name() {
  _source_path=${1?First parameter should be the source path}

  # Ensure exists at least empty
  helm_args=${helm_args:-}

  # shellcheck disable=SC2086
  output=$("$HELM_BIN" inspect chart $helm_args "$_source_path")
  name=$(echo "$output" | grep -e '^name: ' | cut -d' ' -f2)
  echo "$name"
  [ -n "$name" ]
}

# main(raw_uri)
main() {
  helm_args="" # "$1 $2 $3"
  _raw_uri=$4  # eg: git+https://git.com/user/repo@path/to/charts/index.yaml?ref=master


  # If defined, use $HELM_GIT_HELM_BIN as $HELM_BIN.
  if [ -n "${HELM_GIT_HELM_BIN:-}" ]
  then
    export HELM_BIN="${HELM_GIT_HELM_BIN}"
  # If not, use $HELM_BIN after sanitizing it or default to 'helm'.
  elif
    [ -z "$HELM_BIN" ] ||
    # terraform-provider-helm: https://github.com/aslafy-z/helm-git/issues/101
    echo "$HELM_BIN" | grep -q "terraform-provider-helm" ||
    # helm-diff plugin: https://github.com/aslafy-z/helm-git/issues/107
    echo "$HELM_BIN" | grep -q "diff"
  then
    export HELM_BIN="helm"
  fi

  # Parse URI
  string_starts "$_raw_uri" "$url_prefix" ||
    error "Invalid format, got '$_raw_uri'. $error_invalid_prefix"

  # Thanks goes to https://stackoverflow.com/a/63993578
  readonly URI_REGEX='^([^:/?#]+):(//((([^/?#]+)@)?([^/?#]+)?))?(/([^?#]*))(\?([^#]*))?(#(.*))?$'

  _uri_scheme=$(echo "$_raw_uri" | sed -Ene "s'$URI_REGEX'\1'p")
  readonly _uri_scheme
  _uri_authority=$(echo "$_raw_uri" | sed -Ene "s'$URI_REGEX'\3'p")
  readonly _uri_scheme
  _uri_path=$(echo "$_raw_uri" | sed -Ene "s'$URI_REGEX'\8'p")
  readonly _uri_scheme
  _uri_query=$(echo "$_raw_uri" | sed -Ene "s'$URI_REGEX'\9'p")
  readonly _uri_scheme

  git_scheme=$(echo "$_uri_scheme" | sed -e 's/^git+//')
  readonly git_scheme="$git_scheme"
  string_contains "$allowed_protocols" "$git_scheme" ||
    error "$error_invalid_protocol"

  git_repo_path=$(echo "${_uri_path}" | cut -d'@' -f 1)
  readonly git_repo_path

  git_file_path=$(echo "${_uri_path}" | cut -d'@' -f 2)
  readonly git_file_path

  helm_dir=$(dirname "${git_file_path}" | sed -r '/^[\.|/]$/d')
  readonly helm_dir

  helm_file=$(basename "${git_file_path}")
  readonly helm_file

  git_repo="${git_scheme}://${_uri_authority}/${git_repo_path}"
  readonly git_repo

  git_ref=$(echo "$_uri_query" | sed '/^.*ref=\([^&#]*\).*$/!d;s//\1/')
  # TODO: Validate git_ref
  if [ -z "$git_ref" ]; then
    warning "git_ref is empty, defaulted to 'master'. Prefer to pin GIT ref in URI."
    git_ref="master"
  fi
  readonly git_ref

  git_sparse=$(echo "$_uri_query" | sed '/^.*sparse=\([^&#]*\).*$/!d;s//\1/')
  [ -z "$git_sparse" ] && git_sparse=1
  readonly git_sparse

  helm_depupdate=$(echo "$_uri_query" | sed '/^.*depupdate=\([^&#]*\).*$/!d;s//\1/')
  [ -z "$helm_depupdate" ] && helm_depupdate=1
  readonly helm_depupdate

  helm_package=$(echo "$_uri_query" | sed '/^.*package=\([^&#]*\).*$/!d;s//\1/')
  [ -z "$helm_package" ] && helm_package=1
  readonly helm_package

  debug "repo: ${git_repo} ref: ${git_ref} path: ${helm_dir} file: ${helm_file} sparse: ${git_sparse} depupdate: ${helm_depupdate} package: ${helm_package}"
  readonly helm_repo_uri="git+${git_repo}@${helm_dir}?ref=${git_ref}&sparse=${git_sparse}&depupdate=${helm_depupdate}&package=${helm_package}"
  debug "helm_repo_uri: $helm_repo_uri"

  if ${CACHE_CHARTS}; then
    _request_hash=$(echo "${_raw_uri}" | md5sum | cut -d " " -f1)

    _cache_folder="${HELM_GIT_CHART_CACHE}/${_request_hash}"

    _cached_file="${_cache_folder}/${helm_file}"
    if [ -f "${_cached_file}" ]; then
        debug "Returning cached helm request: ${_cached_file}"
        cat "${_cached_file}"
        return 0
    else
        debug "Helm request not found in cache ${_cached_file}"
        mkdir -p "${_cache_folder}"
    fi
  fi

  # Setup cleanup trap
  # shellcheck disable=SC2317
  cleanup() {
    rm -rf "$git_root_path"  "${helm_home_target_path:-}"
    ${CACHE_CHARTS} || rm -rf "${helm_target_path:-}"
  }
  trap cleanup EXIT

  git_root_path="$(mktemp -d "$TMPDIR/helm-git.XXXXXX")"
  readonly git_root_path="$git_root_path"
  git_sub_path=$(path_join "$git_root_path" "$helm_dir")
  readonly git_sub_path="$git_sub_path"
  git_checkout "$git_sparse" "$git_root_path" "$git_repo" "$git_ref" "$helm_dir" ||
    error "Error while git_sparse_checkout"

  if [ -f "$helm_dir/$helm_file" ]; then
    cat "$helm_dir/$helm_file"
    return
  fi

  if ${CACHE_CHARTS}; then
    helm_target_path="${_cache_folder}"
  else
    helm_target_path="$(mktemp -d "$TMPDIR/helm-git.XXXXXX")"
  fi

  readonly helm_target_path="$helm_target_path"
  helm_target_file="$(path_join "$helm_target_path" "$helm_file")"
  readonly helm_target_file="$helm_target_file"

  # Set helm home
  if helm_v2; then
    debug "helm2 detected. initializing helm home"
    helm_home=$("$HELM_BIN" home)
    if [ -z "$helm_home" ]; then
      helm_home_target_path="$(mktemp -d "$TMPDIR/helm-git.XXXXXX")"
      readonly helm_home_target_path="$helm_home_target_path"
      helm_init "$helm_home_target_path" || error "Couldn't init helm"
      helm_home="$helm_home_target_path"
    fi
    helm_args="$helm_args --home=$helm_home"
  fi

  chart_search_root="$git_sub_path"

  chart_search=$(find "$chart_search_root" -maxdepth 2 -name "Chart.yaml" -print)
  chart_search_count=$(echo "$chart_search" | wc -l)

  echo "$chart_search" | {
    while IFS='' read -r chart_yaml_file; do
      chart_path=$(dirname "$chart_yaml_file")
      chart_name=$(helm_inspect_name "$chart_path")

      if [ "$helm_depupdate" = "1" ]; then
        helm_dependency_update "$chart_path" ||
          error "Error while helm_dependency_update"
      fi
      if [ "$helm_package" = "1" ]; then
      helm_package "$helm_target_path" "$chart_path" "$chart_name" ||
        error "Error while helm_package"
      fi
    done
  }

  [ "$chart_search_count" -eq "0" ] &&
    error "No charts have been found"

  helm_index "$helm_target_path" "$helm_repo_uri" ||
    error "Error while helm_index"

  debug "Returning target: $helm_target_file"
  cat "$helm_target_file"
}
