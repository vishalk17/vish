#!/bin/bash

REPO_URL="http://registry.8081/repository/"
USER="admin"
PASSWORD="nM"
BUCKET="docker-registary-jenkins-test"
KEEP_IMAGES=3

while true; do  # Loop until condition is met
    IMAGES=$(curl --silent -X GET -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -u ${USER}:${PASSWORD} "${REPO_URL}${BUCKET}/v2/_catalog" | jq .repositories | jq -r '.[]' )

    TAGS_TO_DELETE=0

    for IMAGE_NAME in ${IMAGES}; do
        TAGS=$(curl --silent -X GET -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -u ${USER}:${PASSWORD} "${REPO_URL}${BUCKET}/v2/${IMAGE_NAME}/tags/list" | jq .tags | jq -r '.[]' )
        TAG_COUNT=$(echo $TAGS | wc -w)

        if [ "${TAG_COUNT}" -gt "${KEEP_IMAGES}" ]; then
            TAGS_TO_DELETE=$((TAGS_TO_DELETE + TAG_COUNT - KEEP_IMAGES))

            # Delete excess tags for this image
            for TAG in ${TAGS}; do
                COUNTER=0
                while [ "${COUNTER}" -lt "${TAG_COUNT}-${KEEP_IMAGES}" ]; do
                    IMAGE_SHA=$(curl --silent -I -X GET -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -u ${USER}:${PASSWORD} "${REPO_URL}${BUCKET}/v2/${IMAGE_NAME}/manifests/$TAG" | grep Docker-Content-Digest | cut -d ":" -f3 | tr -d '\r')
                    DEL_URL="${REPO_URL}${BUCKET}/v2/${IMAGE_NAME}/manifests/sha256:${IMAGE_SHA}"
                    RET="$(curl --silent -k -X DELETE -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -u ${USER}:${PASSWORD} $DEL_URL)"
                    COUNTER=$((COUNTER + 1))
                done
            done
        fi
    done

    if [ "${TAGS_TO_DELETE}" -eq 0 ]; then  # Exit loop if no tags were deleted
        echo "Desired number of tags has been reached."
        break
    fi
done
