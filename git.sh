#!/usr/bin/env sh

# https://github.com/aslafy-z/helm-git
# See Helm plugins documentation: https://docs.helm.sh/using_helm/#downloader-plugins

set -e

error() {
   echo "Error in plugin 'helm-git': $*" >&2
   cleanup
   exit 1
}

URI=$4 # eg: git+https://github.com/jetstack/cert-manager:release-0.5/contrib/charts/index.yaml
REPO=$(echo "$URI" | rev | cut -d':' -f2- | rev | sed -e "s/^git+//") # eg: https://github.com/jetstack/cert-manager
REFPATH=$(echo "$URI" | rev | cut -d':' -f1 | rev) # eg: release-0.5/contrib/charts/index.yaml
REF=$(echo "$REFPATH" | cut -d'/' -f1) # eg: release-0.5
CHARTSPATH=$(echo "$REFPATH" | cut -d'/' -f2- | rev | cut -d '/' -f2- | rev) # eg: contrib/charts
FILE=$(echo "$REFPATH" | rev | cut -d'/' -f1 | rev) # index.yaml

echo "REPO:$REPO" "REF:$REF" "PATH:$CHARTSPATH" "FILE:$FILE" >&2

# make a temp dir
OLDPATH=$(pwd)
TMPPATH=$(mktemp -d)
cd "$TMPPATH" > /dev/null
cleanup() {
  cd "$OLDPATH" > /dev/null
  rm -rf "$TMPPATH"
}

# fetch target repo
git init --quiet
git config core.sparseCheckout true
git remote add origin "$REPO"
echo "$CHARTSPATH/*" > .git/info/sparse-checkout
git pull --depth=1 origin "$REF" >/dev/null 2>&1

if ! [ -d "$CHARTSPATH" ]; then
  error "$REF/$CHARTSPATH does not exists"
fi

# build helm repo
if ! [ -f "$CHARTSPATH/$FILE" ]; then
  cd "$CHARTSPATH" >/dev/null

  find . -maxdepth 1 -type d ! -name ".*" -print -exec sh -c \
    'chart="$1"; helm dependency update --skip-refresh "$chart"; helm package --save=false "$chart"' \
  _ {} \; >/dev/null 2>&1
  
  helm repo index --url="git+$REPO:$REF/$CHARTSPATH" . >/dev/null 2>&1
  cd "$TMPPATH" >/dev/null

  ! [ -f "$CHARTSPATH/$FILE" ] && error "$REF/$CHARTSPATH/$FILE does not exists"
fi

cat "$CHARTSPATH/$FILE"

cleanup
