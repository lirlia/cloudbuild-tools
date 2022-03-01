#!/bin/bash
set -x
set -o pipefail
set -o nounset
set -o errexit

CMDNAME=${0##*/}
echoerr() { echo "$@" 1>&2; }

usage() {
    cat <<USAGE >&2
Usage:
    $CMDNAME --current_build_id \$BUILD_ID [--branch_name \$BRANCH_NAME] [--region \$REGION] [--same_trigger_only]
    --current_build_id \$BUILD_ID  Current Build Id
    --branch_name \$BRANCH_NAME    Trigger branch (aka head branch)
                                    (optional, defaults to current build substitutions.BRANCH_NAME)
    --region \$REGION              Region (if you use CloudBuild Private Pool)
    --same_trigger_only            Only cancel builds with the same Trigger Id as current build’s trigger id
                                    (optional, defaults to false = cancel all matching branch)
USAGE
    exit 1
}

SAME_TRIGGER_ONLY=0
REGION=

# Process arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --current_build_id)
        CURRENT_BUILD_ID="$2"
        if [[ $CURRENT_BUILD_ID == "" ]]; then break; fi
        shift 2
        ;;
    --branch_name)
        TARGET_BRANCH="$2"
        shift 2
        ;;
    --region)
        REGION="--region $2"
        shift 2
        ;;
    --same_trigger_only)
        SAME_TRIGGER_ONLY=1
        shift 1
        ;;
    --help)
        usage
        ;;
    *)
        echoerr "Unknown argument: $1"
        usage
        ;;
    esac
done

if [[ "$CURRENT_BUILD_ID" == "" ]]; then
    echo "Error: you need to provide Build Id"
    usage
fi

# Wait for credential to be downloaded as it may not have been downloaded yet
NEXT_WAIT_TIME=0
RETRY_COUNT=4
until gcloud builds list --limit 1 > /dev/null;
do
    if [ $NEXT_WAIT_TIME -ge $RETRY_COUNT ]; then
        echo "retry count exceeded: $NEXT_WAIT_TIME" >&2
        exit 1
    fi
    sleep $(( NEXT_WAIT_TIME++ ))
done

# Get the trigger name / start time / branch name from the build ID
QUERY_BUILD=$(gcloud builds describe "$CURRENT_BUILD_ID" --format="value(buildTriggerId, startTime, substitutions.BRANCH_NAME)" $REGION)
read -r BUILD_TRIGGER_ID BUILD_START_TIME BUILD_BRANCH <<<"$QUERY_BUILD"

# If --branch_name is not specified, the branch name obtained from the build ID will be used.
if [[ "$TARGET_BRANCH" == "" ]]; then
    TARGET_BRANCH="$BUILD_BRANCH"
fi

# create filter
FILTERS="id!=$CURRENT_BUILD_ID AND startTime<$BUILD_START_TIME AND substitutions.BRANCH_NAME=$TARGET_BRANCH"

# Add to filter if --same_trigger_only is enabled
if [[ $SAME_TRIGGER_ONLY -eq 1 ]]; then
    # Get Trigger Id from current build
    FILTERS="$FILTERS AND buildTriggerId=$BUILD_TRIGGER_ID"
    echo "Filtering Trigger Id: $BUILD_TRIGGER_ID"
fi

echo "Filtering ongoing builds for branch '$TARGET_BRANCH' started before: $BUILD_START_TIME"
echo "$FILTERS"

# Cancel the job with the acquired build ID
gcloud builds list --ongoing --filter="$FILTERS" --format="value(id)" $REGION \
    | xargs -I{} -P8 sh -c "echo {} ; gcloud builds cancel {} $REGION || true"
