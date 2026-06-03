#!/bin/bash

set -eux

HOST="http://opencast:8080"
USER="admin"
PASSWORD="opencast"
WORKFLOW='fast'

echo "Waiting for Opencast to accept HTTP traffic..."
until curl -s -f -u "${USER}:${PASSWORD}" "${HOST}/info/me.json" > /dev/null; do
    sleep 3
done
echo "Opencast is ready! Proceeding with ingest..."

echo "Creating JWT unknown user..."

curl -s -u "${USER}:${PASSWORD}" "${HOST}/admin-ng/users/" \
    -F username='unknown-jwt-user' \
    -F password='unknown-jwt-user' \
    -F name='unknown-jwt-user' \
    -F email='no-mail@jwt.invalid' \
    -F roles='[{'name': 'ROLE_STUDIO', 'type': 'INTERNAL'}, {'name': 'ROLE_EDITOR', 'type': 'INTERNAL'}, {'name': 'ROLE_USER_UNKNOWN_JWT_USER', 'type': 'INTERNAL'}, {'name': 'ROLE_USER', 'type': 'INTERNAL'}, {'name': 'ROLE_JWT_USER', 'type': 'INTERNAL'}]'

echo "JWT unknown user created!"

NOW=$(date +%s)

STARTDATE=$(date -u -d "@$((NOW))" +%Y-%m-%d)
STARTTIME=$(date -u -d "@$((NOW))" +%H:%MZ)

SERIESID=$(curl -s -u "${USER}:${PASSWORD}" "${HOST}/api/series" \
    -F metadata='[{"label": "Opencast Series DublinCore","flavor": "dublincore/series","fields": [{"id": "title","value": "Course_Series_2"}]}]' \
    -F acl='[{"allow":true,"action":"write","role":"ROLE_ADMIN"},{"allow":true,"action":"read","role":"ROLE_ADMIN"},{"allow":true,"action":"write","role":"ROLE_GROUP_MH_DEFAULT_ORG_EXTERNAL_APPLICATIONS"},{"allow":true,"action":"read","role":"ROLE_GROUP_MH_DEFAULT_ORG_EXTERNAL_APPLICATIONS"},{"allow":true,"action":"write","role":"2_Instructor"},{"allow":true,"action":"read","role":"2_Instructor"},{"allow":true,"action":"read","role":"2_Learner"},{"allow":true,"action":"write","role":"120000_Instructor"},{"allow":true,"action":"read","role":"120000_Instructor"},{"allow":true,"action":"read","role":"120000_Learner"}]' \
    | sed -n 's/.*"identifier": *"\([^"]*\)".*/\1/p')

echo "Created Series ID: ${SERIESID}"

EVENTID=$(curl -u "${USER}:${PASSWORD}" "${HOST}/api/events" \
    -F metadata='[{"flavor":"dublincore/episode","fields":[{"id":"title","value":"demo"},{"id":"description","value":"This is a demo video"},{"id":"startDate","value":"'"${STARTDATE}"'"},{"id":"startTime","value":"'"${STARTTIME}"'"},{"id":"isPartOf","value":"'"${SERIESID}"'"}]}]' \
    -F acl='[{"allow":true,"action":"write","role":"ROLE_ADMIN"},{"allow":true,"action":"read","role":"ROLE_ADMIN"},{"allow":true,"action":"write","role":"ROLE_GROUP_MH_DEFAULT_ORG_EXTERNAL_APPLICATIONS"},{"allow":true,"action":"read","role":"ROLE_GROUP_MH_DEFAULT_ORG_EXTERNAL_APPLICATIONS"},{"allow":true,"action":"write","role":"2_Instructor"},{"allow":true,"action":"read","role":"2_Instructor"},{"allow":true,"action":"read","role":"2_Learner"},{"allow":true,"action":"write","role":"120000_Instructor"},{"allow":true,"action":"read","role":"120000_Instructor"},{"allow":true,"action":"read","role":"120000_Learner"}]' \
    -F processing='{"workflow":"fast","configuration":{"flagForCutting":"false","flagForReview":"false","publishToEngage":"true","publishToHarvesting":"true","straightToPublishing":"true"}}' \
    -F presenter=@video.mp4 \
    | sed -n 's/.*"identifier": *"\([^"]*\)".*/\1/p')

echo "Created Event ID: ${EVENTID}"

curl -u "${USER}:${PASSWORD}" "${HOST}/api/playlists" \
    -F playlist='{"title":"Demo Opencast Playlist","description":"This is a demo playlist","creator":"Opencast","entries":[{"contentId":"'"${EVENTID}"'","type":"EVENT"}],"accessControlEntries":[{"allow":true,"action":"write","role":"ROLE_ADMIN"},{"allow":true,"action":"read","role":"ROLE_ADMIN"},{"allow":true,"action":"write","role":"ROLE_GROUP_MH_DEFAULT_ORG_EXTERNAL_APPLICATIONS"},{"allow":true,"action":"read","role":"ROLE_GROUP_MH_DEFAULT_ORG_EXTERNAL_APPLICATIONS"},{"allow":true,"action":"write","role":"2_Instructor"},{"allow":true,"action":"read","role":"2_Instructor"},{"allow":true,"action":"read","role":"2_Learner"},{"allow":true,"action":"write","role":"120000_Instructor"},{"allow":true,"action":"read","role":"120000_Instructor"},{"allow":true,"action":"read","role":"120000_Learner"}]}'

echo "Waiting for Event to be processed..."

while true; do
    RESPONSE=$(curl -s -u "${USER}:${PASSWORD}" "${HOST}/api/events/${EVENTID}?sign=false&withacl=false&withmetadata=false&withscheduling=false&withpublications=false&includeInternalPublication=false")

    if echo "$RESPONSE" | grep -q '"processing_state"[[:space:]]*:[[:space:]]*"SUCCEEDED"'; then
        break
    fi

    echo "Event ${EVENTID} is still processing... checking again in 5 seconds."
    sleep 10
done

echo "Event is ready, exiting the service!"
