#!/usr/bin/env bash
set -e

while getopts t:a: option
do
  case "${option}"
  in
    t) TOOL=${OPTARG};;
    a) ACCOUNT=${OPTARG};;
    *) echo "usage: $0 [-d] [-r]" >&2
           exit 1 ;;
  esac
done

export CURRENT_USER=$(aws sts get-caller-identity | jq -r '.Arn' | awk -F'/' '{print $2}')

echo "current user is: ${CURRENT_USER}"

if [ "${CURRENT_USER}" == "integrations-ci" ]
then
  export ROLE="integrations-ci"
else
  export ROLE="operator"
fi

export SECRET_STRING=$(aws sts assume-role \
--role-arn "arn:aws:iam::${ACCOUNT}:role/${ROLE}" \
--role-session-name AWSCLI-Session | \
jq -r '.Credentials.SessionToken + " " + .Credentials.SecretAccessKey + " " + .Credentials.AccessKeyId')

#local export so they only exist in this stage
export AWS_ACCESS_KEY_ID=$(echo "${SECRET_STRING}" | awk -F' ' '{print $3}')
export AWS_SECRET_ACCESS_KEY=$(echo "${SECRET_STRING}" | awk -F' ' '{print $2}')
export AWS_SESSION_TOKEN=$(echo "${SECRET_STRING}" | awk -F' ' '{print $1}')

aws codeartifact login --tool "${TOOL}" \
--repository opg-pip-shared-code-dev \
--domain opg-moj \
--domain-owner "${ACCOUNT}" \
--region eu-west-1
