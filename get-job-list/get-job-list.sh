#!/bin/bash
# Obtains the build IDs of Cloud Build jobs that were executed before the specified build ID and hit various conditions.

set -o pipefail
set -o nounset
set -o errexit

CMDNAME=${0##*/}

function prefail() { echo "$@" 1>&2; usage; exit 1; }
function usage() {
    cat <<USAGE >&2
Usage:
    $CMDNAME [OPTIONS]

Options
    --build_id [BUILD_ID]                           Job to use for search
    --check_trigger_name_regex [TRIGGER_NAME_REGEX] Regular expression used when searching for build trigger names.
    --limit [NUMBER]                                Limit of the number of searches.
    --disable_on_going                              Normally, only running jobs are targeted, but when this flag is set, all jobs are targeted.
    --region [REGION_NAME]                          Please specify the region when you use Private Pool.
    --help / -h
USAGE
}

LIMIT=10                    # Number of Cloudbuild jobs to search for
BUILD_ID=dummy              # This is the job ID from which to start the search. Check for jobs created before this job
TRIGGER_NAME_REGEX=dummy    # The name of the trigger that executed the job to be searched
ONGOING_FLAG=true           # Set to true to target only ongoing (currently running) jobs
REGION=""                   # Required for use with worker pools


# Process arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --build_id)
        BUILD_ID="$2"
        shift 2
        ;;
    --check_trigger_name_regex)
        TRIGGER_NAME_REGEX="$2"
        shift 2
        ;;
    --limit)
        LIMIT="$2"
        shift 2
        ;;
    --disable_on_going)
        ONGOING_FLAG="false"
        shift 1
        ;;
    --region)
        REGION="--region $2"
        shift 2
        ;;
    --help|-h)
        usage
        exit 0
        ;;
    *)
        prefail "Unknown argument: $1"
        ;;
    esac
done

# Return a list of jobs that match the criteria
function getOngoingJobListBeforeSpecificJob() {

    local build_start_time=$(gcloud builds describe $BUILD_ID --format='value(startTime)' $REGION)
    local args=(
        # Sort by job creation order
        --sort-by=create_time
        # Number of jobs to search
        --limit "${LIMIT}"
        # Get build ID
        --format="value(ID)"
        # Filter the search.
        --filter="id!=$BUILD_ID \
                    AND startTime<=$build_start_time\
                    AND substitutions.TRIGGER_NAME~$TRIGGER_NAME_REGEX"
        # The region to use in the worker pool.
        $REGION
    )
    [ $ONGOING_FLAG = true ] && args+=(--ongoing)

    # Get a list of build IDs of running jobs
    gcloud builds list "${args[@]}"
}

getOngoingJobListBeforeSpecificJob
