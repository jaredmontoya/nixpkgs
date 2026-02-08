#!/usr/bin/env nix-shell
#!nix-shell -I nixpkgs=../../../.. -i bash -p nix curl jq prefetch-yarn-deps nix-prefetch-github

ORG="ItzCrazyKns"
PROJ="Perplexica"

if [ "$#" -gt 1 ] || [[ "$1" == -* ]]; then
  echo "Regenerates packaging data for $PROJ."
  echo "Usage: $0 [git release tag]"
  exit 1
fi

tag="$1"

set -euox pipefail

if [ -z "$tag" ]; then
  tag="$(
    curl "https://api.github.com/repos/$ORG/$PROJ/releases?per_page=1" |
      jq -r '.[0].tag_name'
  )"
fi

src="https://raw.githubusercontent.com/$ORG/$PROJ/$tag"
src_hash=$(nix-prefetch-github $ORG $PROJ --rev ${tag} | jq -r .hash)

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

pushd $tmpdir
curl -O "$src/yarn.lock"
yarn_hash=$(prefetch-yarn-deps yarn.lock | tail -1)
popd

cat >pin.json <<EOF
{
  "version": "$(echo $tag | grep -P '(\d|\.)+' -o)",
  "srcHash": "$src_hash",
  "yarnHash": "$yarn_hash"
}
EOF
