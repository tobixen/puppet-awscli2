#!/bin/bash
#
# forge-publish.sh - Publish module to puppet forge
#
# Eric Sturdivant (sturdiva@umd.edu)
#

set -e

PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin; export PATH

pdk build

(
    echo -n '{"file":"'
    base64 -w 0 pkg/umd-awscli2-*.tar.gz
    echo '"}'
) | curl -v \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer ${FORGE_API_KEY}" \
         -d @- \
         -o /tmp/forge-publish.json \
         https://forgeapi.puppet.com/v3/releases

# curl doesn't exit w/error codes on some (all?) HTTP errors.
cat /tmp/forge-publish.json
echo ""

uri=`jq .file_uri /tmp/forge-publish.json`
if [ -z "${uri}" -o "${uri}" = "null" ]; then
  echo "failed to publish to forge"
  exit 1
else
  echo "published to forge at ${uri}"
  exit 0
fi

