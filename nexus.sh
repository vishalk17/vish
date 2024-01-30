#!/bin/bash

REPO_URL="https://repository.xxx.net/repository/"
USER="admin"
PASSWORD="datpassword"

BUCKET="portal-docker"
KEEP_IMAGES=10

IMAGES=$(curl --silent -X GET -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -u ${USER}:${PASSWORD} "${REPO_URL}${BUCKET}/v2/_catalog" | jq .repositories | jq -r '.[]' )

echo ${IMAGES}

for IMAGE_NAME in ${IMAGES}; do
 echo ${IMAGE_NAME}

   TAGS=$(curl --silent -X GET -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -u ${USER}:${PASSWORD} "${REPO_URL}${BUCKET}/v2/${IMAGE_NAME}/tags/list" | jq .tags | jq -r '.[]' )
   
   TAG_COUNT=$(echo $TAGS | wc -w)
   
   let TAG_COUNT_DEL=${TAG_COUNT}-${KEEP_IMAGES}
   COUNTER=0
   
   echo "THERE ARE ${TAG_COUNT} IMAGES FOR ${IMAGE_NAME}"
   
   ## skip if smaller than keep
   if [ "${KEEP_IMAGES}" -gt "${TAG_COUNT}" ]
    then
      echo "There are only ${TAG_COUNT} Images for ${IMAGE_NAME} - nothing to delete"
      continue
   fi
   
   for TAG in ${TAGS}; do
    let COUNTER=COUNTER+1
    if [ "${COUNTER}" -gt "${TAG_COUNT_DEL}" ]
     then
      break;
    fi
    
    IMAGE_SHA=$(curl --silent -I -X GET -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -u ${USER}:${PASSWORD} "${REPO_URL}${BUCKET}/v2/${IMAGE_NAME}/manifests/$TAG" | grep Docker-Content-Digest | cut -d ":" -f3 | tr -d '\r')
    echo "DELETE ${TAG} ${IMAGE_SHA}";
    DEL_URL="${REPO_URL}${BUCKET}/v2/${IMAGE_NAME}/manifests/sha256:${IMAGE_SHA}"
    RET="$(curl --silent -k -X DELETE -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' -u ${USER}:${PASSWORD} $DEL_URL)"
   
   done;
done;
