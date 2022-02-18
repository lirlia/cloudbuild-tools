# Cancelot

This tool is a shell version of Cancelot published in cloud-builders-community. 

Inspired by siberex's [gist](https://gist.github.com/siberex/bb0540b208019382d08732cc6dd59007)

## Feature

This tool is intended to run on Cloud Build.
By incorporating it into the Cloud Build steps, you will be able to:

- Cancel a specific build
- Cancel build job associated with the same git branch

## Usage

```bash
Usage:
    cancelot.sh --current_build_id $BUILD_ID [--branch_name $BRANCH_NAME] [--same_trigger_only]
    --current_build_id $BUILD_ID  Current Build Id
    --branch_name $BRANCH_NAME    Trigger branch (aka head branch)
                                    (optional, defaults to current build substitutions.BRANCH_NAME)
    --region $REGION              Region (if you use CloudBuild Private Pool)
    --same_trigger_only           Only cancel builds with the same Trigger Id as current build’s trigger id
                                    (optional, defaults to false = cancel all matching branch)
```

## Usage in CloudBuild yaml

```yaml
steps:
  - id: run-cancelot
    name: gcr.io/google.com/cloudsdktool/cloud-sdk:latest
    entrypoint: 'bash'
    args:
      - -c
      - |

        curl -sS https://raw.githubusercontent.com/lirlia/cloudbuild-tools/main/cancelot/cancelot.sh > cancelot.sh
        chmod +x cancelot.sh
        ./cancelot.sh --current_build_id $BUILD_ID --branch_name $BRANCH_NAME --same_trigger_only
```
