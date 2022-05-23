# get-job-list

## Feature

This tool is intended to run on Cloud Build.
By incorporating it into the Cloud Build steps, you will be able to:

- Get filtered build jobs

## Usage

```bash
Usage:
    get-filtered-cloudbuild-job-list.sh [OPTIONS]

Options
    --build_id [BUILD_ID]                           Job to use for search
    --check_trigger_name_regex [TRIGGER_NAME_REGEX] Regular expression used when searching for build trigger names.
    --limit [NUMBER]                                limit of the number of searches.
    --disable_on_going                              Normally, only running jobs are targeted, but when this flag is set, all jobs are targeted.
    --region [REGION_NAME]                          Please specify the region when you use Private Pool.
    --help / -h
```

## Usage in CloudBuild yaml

```yaml
steps:
  - id: get-filtered-job-list
    name: gcr.io/google.com/cloudsdktool/cloud-sdk:latest
    entrypoint: 'bash'
    args:
      - -c
      - |

        curl -sS https://raw.githubusercontent.com/lirlia/cloudbuild-tools/main/get-job-list/get-filtered-cloudbuild-job-list.sh > get-filtered-cloudbuild-job-list.sh
        chmod +x get-job-list.sh
        ./get-filtered-cloudbuild-job-list.sh
```
