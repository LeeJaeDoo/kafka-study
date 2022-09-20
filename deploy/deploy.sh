#!/bin/sh

shopt -s expand_aliases

# code base
# https://github.com/techpivot/aws-code-deploy/blob/master/bin/aws-code-deploy.sh
#

if [[ -z $1 ]]; then
  echo "배포 환경을 선택하여 주십시요.  ex: ./deploy.sh [release|dev|qa|stage ...] "
  exit 1
fi

DEPLOY_MODE=$1
SCRIPT_DEBUG=$2

RUN_DIR=$PWD
SCRIPT=$(readlink -f $0 2>/dev/null)
if [[ -z ${SCRIPT} ]]; then
  cd ${0%/*} 2>/dev/null
  SCRIPT=$PWD/${0##*/}
fi

SCRIPT_DIR=$(dirname $SCRIPT)

# 하부 디렉토리까지 모두 검색
if [ -n "$DEPLOY_MODE" ]; then
  SCRIPT_FILES=$(find ./ -regex ".*\.$DEPLOY_MODE\(\..*\)?" -type f 2>/dev/null)
  #SCRIPT_FILES=$(find ./ -regex ".*\.$DEPLOY_MODE\(\..*\)?" 2> /dev/null) # 디렉토리 적용 원할 경우
  #배포 모드에 맞게 파일 교체
  if [[ ! -z ${SCRIPT_FILES} ]]; then
    for file in ${SCRIPT_FILES}; do
      _fileName=$(basename "$file" | sed -r "s#(.*)\.$DEPLOY_MODE(\..*|$)#\1\2#")
      _fileDir=$(dirname $file)
      echo "overwrite : $file > $_fileName"
      mv -f "$file" "$_fileDir/$_fileName"
      touch -c "$_fileDir/$_fileName"
      # cat "$file" > "$_fileDir/$_fileName"
    done
  fi
fi

#환경 파일 로드
source ./env.sh

## -- [환경 설정 END] ------------------

#https://wiki.kldp.org/HOWTO/html/Adv-Bash-Scr-HOWTO/options.html#OPTIONSREF
#실패할 경우는 바로 스크립트 실행을 종료
set +e
set -o noglob

if [[ "$SCRIPT_DEBUG" == "true" ]]; then
  #명령의 추적을 인쇄
  set -x
else
  set +x
fi

#
# Common Output Styles
#
alias step="echo ➜"
alias progress=" echo ➟"
alias info="  echo ※"
alias success="   echo ✔"
alias error="   echo ✖"
alias warnError="   echo ✖"
alias warnNotice="   echo ✖"
alias note=" echo [Note]: "

# Runs the specified command and logs it appropriately.
#   $1 = command
#   $2 = (optional) error message
#   $3 = (optional) success message
#   $4 = (optional) global variable to assign the output to
runCommand() {
  command="$1"
  info "$1"
  output="$(eval $command 2>&1)"
  ret_code=$?

  if [ $ret_code != 0 ]; then
    warnError "$output"
    if [ ! -z "$2" ]; then
      error "$2"
    fi
    exit $ret_code
  fi
  if [ ! -z "$3" ]; then
    success "$3"
  fi
  if [ ! -z "$4" ]; then
    eval "$4='$output'"
  fi
}

typeExists() {
  if [ $(type -P $1) ]; then
    return 0
  fi
  return 1
}

jsonValue() {
  key=$1
  num=$2
  awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$key'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

#installAwsCli() {
#  if ! typeExists "pip"; then
#    progress "Installing Python PIP"
#    runCommand "yum install python-pip"
#    success "Installing PIP (`pip --version`) succeeded"
#  fi
#
#  progress "Installing AWS CLI"
#  runCommand "pip install awscli"
#}

# Check variables

if [ -z "$DEPLOY_APPLICATION_NAME" ]; then
  error "배포할 애플리케이션 명을 지정하여 주십시요. \"\$DEPLOY_APPLICATION_NAME\""
  exit 1
fi

if [ -z "$DEPLOY_DEPLOYMENT_GROUP_NAME" ]; then
  error "배포 그룹을 지정하여 주십시요. \"\$DEPLOY_DEPLOYMENT_GROUP_NAME\""
  exit 1
fi

if [ -z "$DEPLOY_S3_BUCKET" ]; then
  error "배포 업로드를 위한 Amazon S3 버킷을 지정하여 주십시요.  \"\$DEPLOY_S3_BUCKET\""
  exit 1
fi

if [ -z "$DEPLOY_APP_SOURCE" ]; then
  error "배포할 소스코드가 폴더나 배포 아카이브 파일 위치를 지정하여 주십시요. \"\$DEPLOY_APP_SOURCE\""
  exit 1
fi

#if [[ -n "$DEPLOY_DEPLOYMENT_FILE_EXISTS_BEHAVIOR" && ! "$DEPLOY_DEPLOYMENT_FILE_EXISTS_BEHAVIOR" =~ ^(DISALLOW|OVERWRITE|RETAIN)$ ]]; then
#  error "$DEPLOY_DEPLOYMENT_FILE_EXISTS_BEHAVIOR is not a valid option for the \"\$DEPLOY_DEPLOYMENT_FILE_EXISTS_BEHAVIOR\" variable"
#  exit 1
#fi

# ----- Application Source -----
step "Step : Checking Application Source"

APP_SOURCE=${DEPLOY_APP_SOURCE}
if [ ! -d "$APP_SOURCE" -a ! -e "$APP_SOURCE" ]; then
  # Note: Use original variable for output as the readlink can potentially evaluate to ""
  error "배포 대상 소스 위치가 존재하지 않습니다. \"${DEPLOY_APP_SOURCE}\""
  exit 1
fi

if [ -d "$APP_SOURCE" ]; then
  if [ ! -e "$APP_SOURCE/appspec.yml" ]; then
    error "source directory \"${APP_SOURCE}\"에 \"appspec.yml\" 이 존재하지 않음"
    exit 1
  fi

  APPSPEC=$(sed -e "s@#{DEPLOY_TMP}@$DEPLOY_TMP@" -e "s@#{USER_HOME}@$USER_HOME@" -e "s@#{USER}@$USER@" -e "s@#{GROUP}@$GROUP@" "$APP_SOURCE/appspec.yml")
  echo "$APPSPEC" >"$APP_SOURCE/appspec.yml"

  DEPLOY_S3_FILENAME=$(basename "$APP_SOURCE")
  DEPLOYMENT_COMPRESS_ORIG_DIR_SIZE=$(du -hs $APP_SOURCE | awk '{ print $1}')
  APP_LOCAL_FILE="${DEPLOY_S3_FILENAME%.*}.zip"
  APP_LOCAL_TEMP_FILE="/tmp/$APP_LOCAL_FILE"

  #현재 폴더를 압축하여 zip파일로 변경
  runCommand "cd \"$APP_SOURCE\" && zip -rq \"${APP_LOCAL_TEMP_FILE}\" ." \
    "Unable to compress \"$APP_SOURCE\""
  DEPLOYMENT_COMPRESS_FILESIZE=$(ls -lah "${APP_LOCAL_TEMP_FILE}" | awk '{ print $5}')
  BUNDLE_TYPE="zip"
  success "Successfully compressed \"$APP_SOURCE\" ($DEPLOYMENT_COMPRESS_ORIG_DIR_SIZE) into \"$APP_LOCAL_FILE\" ($DEPLOYMENT_COMPRESS_FILESIZE)"
else

  # 변경된 설정 및 스크립트 파일을 배포 파일에 다시 넣음
  APP_SOURCE_BASENAME=$(basename "$APP_SOURCE")
  DEPLOY_S3_FILENAME=$APP_SOURCE_BASENAME
  APP_SOURCE_FILESIZE=$(ls -lah "${APP_SOURCE}" | awk '{ print $5}')
  EXTENSION="${APP_SOURCE##*.}"

  APPSPEC=$(sed -e "s@#{DEPLOY_TMP}@$DEPLOY_TMP@" -e "s@#{USER_HOME}@$USER_HOME@" -e "s@#{USER}@$USER@" -e "s@#{GROUP}@$GROUP@" appspec.yml)
  echo "$APPSPEC" >appspec.yml

  if [ $EXTENSION == "tar" ]; then
    tar -rvf $APP_SOURCE .
    BUNDLE_TYPE="tar"
  elif [ $EXTENSION == "gz" ]; then
    tar -zcvf $APP_SOURCE .
    BUNDLE_TYPE="tgz"
  elif [ $EXTENSION == "zip" ]; then
    zip -ur $APP_SOURCE .
    BUNDLE_TYPE="zip"

  else
    error "지원하지 않는 bundle type: ${APP_SOURCE_BASENAME} - 지원 bundle type tar, zip"
    exit 1
  fi

  APP_LOCAL_FILE=$APP_SOURCE_BASENAME
  APP_LOCAL_TEMP_FILE=$APP_SOURCE

  success "Valid source file: $APP_SOURCE_BASENAME ($APP_SOURCE_FILESIZE)"
fi

# ----- Install AWS Cli -----
# see documentation http://docs.aws.amazon.com/cli/latest/userguide/installing.html
# ---------------------------

# Check AWS is installed
step "Step : AWS Cli Checking"

# AWS-CLI path 적용
export PATH=/usr/local/bin:$PATH

if ! typeExists "aws"; then
  error "AWS Cli가 설치되어 있지 않습니다."
  exit 1
else
  success "aws-cli: $(aws --version 2>&1)"
fi

# ----- Configure -----
# see documentation
#    http://docs.aws.amazon.com/cli/latest/reference/configure/index.html
# ----------------------

step "Step : Configuring AWS"
if [ -z "$DEPLOY_S3_FILENAME" ]; then
  error "S3에  배포할 파일명을 지정하여 주십시요. \"\$DEPLOY_S3_FILENAME\""
  exit 1
fi

if [[ -z "$DEPLOY_KEY" || -z "$DEPLOY_SECRET" || -z "$DEPLOY_REGION" ]]; then
  AWS_CONFIG_LIST=$(aws configure list)
fi

#https://docs.aws.amazon.com/cli/latest/reference/configure/list.html
if [ -z "$DEPLOY_KEY" ]; then
  #액세스 키가 이미 설정되어 있는지 확인
  if [ $(echo ${AWS_CONFIG_LIST} | grep access_key | wc -l) -lt 1 ]; then
    error "No DEPLOY_SECRET and shared access_key credentials"
    exit 1
  fi
else
  $(aws configure set aws_access_key_id $DEPLOY_KEY 2>&1)
fi

if [ -z "$DEPLOY_SECRET" ]; then
  #secret_key 가 이미 설정되어 있는지 확인
  if [ $(echo ${AWS_CONFIG_LIST} | grep secret_key | wc -l) -lt 1 ]; then
    error "No DEPLOY_SECRET and shared secret_key credentials"
    exit 1
  fi
else
  $(aws configure set aws_secret_access_key $DEPLOY_SECRET 2>&1)
fi

if [ -z "$DEPLOY_REGION" ]; then
  #region 이 이미 설정되어 있는지 확인
  if [ $(echo ${AWS_CONFIG_LIST} | grep region | wc -l) -lt 1 ]; then
    error "No DEPLOY_REGION and shared credentials"
    exit 1
  fi
else
  $(aws configure set default.region $DEPLOY_REGION 2>&1)
fi

# ----- Application -----
# see documentation
#    http://docs.aws.amazon.com/cli/latest/reference/deploy/get-application.html
#    http://docs.aws.amazon.com/cli/latest/reference/deploy/create-application.html
# ----------------------
# Application variables
APPLICATION_NAME="$DEPLOY_APPLICATION_NAME"
#APPLICATION_VERSION=${DEPLOY_APPLICATION_VERSION:-${GIT_COMMIT:0:7}}

# Check application exists
step "Step : Checking Application"
APPLICATION_EXISTS="aws deploy get-application --application-name $APPLICATION_NAME"
info "$APPLICATION_EXISTS"
APPLICATION_EXISTS_OUTPUT=$($APPLICATION_EXISTS 2>&1)

if [ $? -ne 0 ]; then
  warnNotice "$APPLICATION_EXISTS_OUTPUT"
  progress "Creating application \"$APPLICATION_NAME\""

  # Create application
  runCommand "aws deploy create-application --application-name $APPLICATION_NAME" \
    "Creating application \"$APPLICATION_NAME\" failed" \
    "Creating application \"$APPLICATION_NAME\" succeeded"
else
  success "Application \"$APPLICATION_NAME\" already exists"
fi

# ----- Deployment Config (optional) -----
# see documentation http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html
# https://docs.aws.amazon.com/ko_kr/codedeploy/latest/userguide/instances-health.html
# ----------------------
DEPLOYMENT_CONFIG_NAME=${DEPLOY_DEPLOYMENT_CONFIG_NAME:-CodeDeployDefault.OneAtATime}
#MINIMUM_HEALTHY_HOSTS=${DEPLOY_MINIMUM_HEALTHY_HOSTS:-type=FLEET_PERCENT,value=75}

# Check deployment config exists
step "Step : Checking Deployment Config"
DEPLOYMENT_CONFIG_EXISTS="aws deploy get-deployment-config --deployment-config-name $DEPLOYMENT_CONFIG_NAME"
info "$DEPLOYMENT_CONFIG_EXISTS"
DEPLOYMENT_CONFIG_EXISTS_OUTPUT=$($DEPLOYMENT_CONFIG_EXISTS 2>&1)

if [ $? -ne 0 ]; then
  warnNotice "$DEPLOYMENT_CONFIG_EXISTS_OUTPUT"
  progress "Creating deployment config \"$DEPLOYMENT_CONFIG_NAME\""

  MINIMUM_HEALTHY_HOSTS=''
  if [ -z "$DEPLOY_MINIMUM_HEALTHY_HOSTS" ]; then
    MINIMUM_HEALTHY_HOSTS=" --minimum-healthy-hosts $DEPLOY_MINIMUM_HEALTHY_HOSTS"
  fi
  # Create application
  runCommand "aws deploy create-deployment-config --deployment-config-name $DEPLOYMENT_CONFIG_NAME $MINIMUM_HEALTHY_HOSTS" \
    "Creating application \"$DEPLOYMENT_CONFIG_NAME\" failed" \
    "Creating application \"$DEPLOYMENT_CONFIG_NAME\" succeeded"
else
  success "Deployment config \"$DEPLOYMENT_CONFIG_NAME\" already exists"
fi

# ----- Deployment Group -----
# see documentation http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment-config.html
# ----------------------
# Deployment group variables
DEPLOYMENT_GROUP=${DEPLOY_DEPLOYMENT_GROUP_NAME:-$DEPLOYTARGET_NAME}
AUTO_SCALING_GROUPS="$DEPLOY_AUTO_SCALING_GROUPS"
EC2_TAG_FILTERS="$DEPLOY_EC2_TAG_FILTERS"
SERVICE_ROLE_ARN="$DEPLOY_SERVICE_ROLE_ARN"

# Check deployment group exists
step "Step : Checking Deployment Group"
DEPLOYMENT_GROUP_EXISTS="aws deploy get-deployment-group --application-name $APPLICATION_NAME --deployment-group-name $DEPLOYMENT_GROUP"
info "$DEPLOYMENT_GROUP_EXISTS"
DEPLOYMENT_GROUP_EXISTS_OUTPUT=$($DEPLOYMENT_GROUP_EXISTS 2>&1)

if [ $? -ne 0 ]; then
  warnNotice "$DEPLOYMENT_GROUP_EXISTS_OUTPUT"
  progress "Creating deployment group \"$DEPLOYMENT_GROUP\" for application \"$APPLICATION_NAME\""

  # Create deployment group
  DEPLOYMENT_GROUP_CREATE="aws deploy create-deployment-group --application-name $APPLICATION_NAME --deployment-group-name $DEPLOYMENT_GROUP --deployment-config-name $DEPLOYMENT_CONFIG_NAME"

  if [ -n "$SERVICE_ROLE_ARN" ]; then
    DEPLOYMENT_GROUP_CREATE="$DEPLOYMENT_GROUP_CREATE --service-role-arn $SERVICE_ROLE_ARN"
  fi
  if [ -n "$AUTO_SCALING_GROUPS" ]; then
    DEPLOYMENT_GROUP_CREATE="$DEPLOYMENT_GROUP_CREATE --auto-scaling-groups $AUTO_SCALING_GROUPS"
  fi
  if [ -n "$EC2_TAG_FILTERS" ]; then
    DEPLOYMENT_GROUP_CREATE="$DEPLOYMENT_GROUP_CREATE --ec2-tag-filters $EC2_TAG_FILTERS"
  fi

  runCommand "$DEPLOYMENT_GROUP_CREATE" \
    "Creating deployment group \"$DEPLOYMENT_GROUP\", application \"$APPLICATION_NAME\" failed" \
    "Creating deployment group \"$DEPLOYMENT_GROUP\", application \"$APPLICATION_NAME\" succeeded"
else
  success "Deployment group \"$DEPLOYMENT_GROUP\" already exists, application \"$APPLICATION_NAME\""
fi

# ----- Push Bundle to S3 -----
# see documentation  http://docs.aws.amazon.com/cli/latest/reference/s3/cp.html
# ----------------------
step "Step : Copying Bundle to S3"
S3_CP="aws s3 cp"
S3_BUCKET=${DEPLOY_S3_BUCKET}
S3_FULL_BUCKET=${S3_BUCKET}

# Strip off any "/" from front and end, but allow inside
S3_KEY_PREFIX=$(echo "${DEPLOY_S3_KEY_PREFIX}" | sed 's/^\/\?\(.*[^\/]\)\/\?$/\1/')

if [ ! -z "${S3_KEY_PREFIX}" ]; then
  S3_FULL_BUCKET="${S3_FULL_BUCKET}/${S3_KEY_PREFIX}"
fi

if [ "${DEPLOY_S3_SSE}" == "true" ]; then
  S3_CP="${S3_CP} --sse AES256"
fi

runCommand "${S3_CP} \"${APP_LOCAL_TEMP_FILE}\" \"s3://${S3_FULL_BUCKET}/${DEPLOY_S3_FILENAME}\"" \
  "Unable to copy bundle \"${APP_LOCAL_TEMP_FILE}\" to S3" \
  "Successfully copied bundle \"${APP_LOCAL_TEMP_FILE}\" to s3://${S3_FULL_BUCKET}/${DEPLOY_S3_FILENAME}"

# ----- S3 Bucket/Key 내부 배포 파일 갯수 제한  -----
# see documentation  http://docs.aws.amazon.com/cli/latest/reference/s3/cp.html
# ----------------------
step "Step : Limiting Deploy Revisions per Bucket/Key"
S3_DEPLOY_LIMIT=${DEPLOY_S3_LIMIT_BUCKET_FILES:-0}
if [ $S3_DEPLOY_LIMIT -lt 1 ]; then
  success "Skipping deploy revision max files per bucket/key."
else
  progress "Checking bucket/key to limit total revisions at ${S3_DEPLOY_LIMIT} files ..."
  S3_LS_OUTPUT=""
  runCommand "aws s3 ls \"s3://$S3_FULL_BUCKET/\"" \
    "Unable to list directory contents \"$S3_BUCKET/\"" \
    "" \
    S3_LS_OUTPUT

  # Sort the output by date first
  #S3_LS_OUTPUT=$(echo "$S3_LS_OUTPUT" | sort)
  #S3_LS_OUTPUT=$(echo "$S3_LS_OUTPUT" | sort --version-sort --field-separator=- -k4,4)
  S3_LS_OUTPUT=$(echo "$S3_LS_OUTPUT" --recursive | sort)

  # Filter out S3 prefixes (These do not count, especially useful in root bucket location)
  S3_FILES=()
  IFS=$'\n'
  for line in $S3_LS_OUTPUT; do
    if [[ ! $line =~ ^[[:space:]]+PRE[[:space:]].*$ ]]; then
      S3_FILES+=("$line")
    fi
  done

  #s3 파일 삭제
  S3_TOTAL_FILES=${#S3_FILES[@]}
  S3_NUMBER_FILES_TO_CLEAN=$(($S3_TOTAL_FILES - $S3_DEPLOY_LIMIT))
  if [ $S3_NUMBER_FILES_TO_CLEAN -gt 0 ]; then
    progress "Removing oldest $S3_NUMBER_FILES_TO_CLEAN file(s) ..."
    for line in "${S3_FILES[@]}"; do
      if [ $S3_NUMBER_FILES_TO_CLEAN -le 0 ]; then
        success "Successfuly removed $(($S3_TOTAL_FILES - $S3_DEPLOY_LIMIT)) file(s)"
        break
      fi
      FILE_LINE=$(expr "$line" : '^.*[0-9]\{2\}\:[0-9]\{2\}\:[0-9]\{2\}[ ]\+[0-9]\+[ ]\+\(.*\)$')
      runCommand "aws s3 rm \"s3://$S3_FULL_BUCKET/$FILE_LINE\""
      ((S3_NUMBER_FILES_TO_CLEAN--))
    done
  else
    success "File count under limit. No need to remove old files. (Total Files = $S3_TOTAL_FILES, Limit = $S3_DEPLOY_LIMIT)"
  fi
fi

# ----- Register Revision -----
# see documentation http://docs.aws.amazon.com/cli/latest/reference/deploy/register-application-revision.html
# ----------------------
step "Step : Registering Revision"

#REGISTER_APP_CMD="aws deploy register-application-revision --application-name \"$APPLICATION_NAME\""

if [ -n "$S3_KEY_PREFIX" ]; then
  S3_LOCATION="bucket=${S3_BUCKET},bundleType=${BUNDLE_TYPE},key=${S3_KEY_PREFIX}/${DEPLOY_S3_FILENAME}"
else
  S3_LOCATION="bucket=${S3_BUCKET},bundleType=${BUNDLE_TYPE},key=${DEPLOY_S3_FILENAME}"
fi

REGISTER_APP_CMD="aws deploy register-application-revision --application-name \"$APPLICATION_NAME\" --s3-location ${S3_LOCATION}"

if [ ! -z "${DEPLOY_REVISION_DESCRIPTION}" ]; then
  REGISTER_APP_CMD="${REGISTER_APP_CMD} --description \"${DEPLOY_REVISION_DESCRIPTION}\""
fi

runCommand "${REGISTER_APP_CMD}" \
  "Registering revision failed" \
  “Registering revision succeeded”

# ----- Create Deployment -----
# see documentation http://docs.aws.amazon.com/cli/latest/reference/deploy/create-deployment.html
# ----------------------
step "Step : Creating Deployment"
DEPLOYMENT_CMD="aws deploy create-deployment --output json --application-name $APPLICATION_NAME --deployment-config-name $DEPLOYMENT_CONFIG_NAME --deployment-group-name $DEPLOYMENT_GROUP --s3-location $S3_LOCATION"

if [ -n "$DEPLOY_DEPLOYMENT_DESCRIPTION" ]; then
  DEPLOYMENT_CMD="$DEPLOYMENT_CMD --description \"$DEPLOY_DEPLOYMENT_DESCRIPTION\""
fi

DEPLOYMENT_OUTPUT=""
runCommand "$DEPLOYMENT_CMD" \
  "Deployment of application \"$APPLICATION_NAME\" on deployment group \"$DEPLOYMENT_GROUP\" failed" \
  "" \
  DEPLOYMENT_OUTPUT

# deploy id 획
DEPLOYMENT_ID=$(echo $DEPLOYMENT_OUTPUT | jsonValue 'deploymentId' | tr -d ' ')
success "Successfully created deployment: \"$DEPLOYMENT_ID\""
note "deployment at: https://console.aws.amazon.com/codedeploy/home#/deployments/$DEPLOYMENT_ID"

# ----- Monitor Deployment -----
# see documentation https://docs.aws.amazon.com/cli/latest/reference/deploy/get-deployment.html
# ----------------------
DEPLOYMENT_OVERVIEW=${DEPLOY_DEPLOYMENT_OVERVIEW:-true}
if [ "true" == "$DEPLOYMENT_OVERVIEW" ]; then
  step "Deployment Overview"

  aws deploy wait deployment-successful --deployment-id $DEPLOYMENT_ID 2>&1

  DEPLOYMENT_GET="aws deploy get-deployment --output json --deployment-id \"$DEPLOYMENT_ID\""
  progress "Monitoring deployment \"$DEPLOYMENT_ID\" for \"$APPLICATION_NAME\" on deployment group $DEPLOYMENT_GROUP ..."
  #  info "$DEPLOYMENT_GET"

  while :; do
    DEPLOYMENT_GET_OUTPUT="$(eval $DEPLOYMENT_GET 2>&1)"
    if [ $? != 0 ]; then
      warnError "$DEPLOYMENT_GET_OUTPUT"
      error "Deployment of application \"$APPLICATION_NAME\" on deployment group \"$DEPLOYMENT_GROUP\" failed"
      exit 1
    fi

    # Deployment Overview
    IN_PROGRESS=$(echo "$DEPLOYMENT_GET_OUTPUT" | jsonValue "InProgress" | tr -d "\r\n ")
    PENDING=$(echo "$DEPLOYMENT_GET_OUTPUT" | jsonValue "Pending" | tr -d "\r\n ")
    SKIPPED=$(echo "$DEPLOYMENT_GET_OUTPUT" | jsonValue "Skipped" | tr -d "\r\n ")
    SUCCEEDED=$(echo "$DEPLOYMENT_GET_OUTPUT" | jsonValue "Succeeded" | tr -d "\r\n ")
    FAILED=$(echo "$DEPLOYMENT_GET_OUTPUT" | jsonValue "Failed" | tr -d "\r\n ")

    if [ "$IN_PROGRESS" == "" ]; then IN_PROGRESS="-"; fi
    if [ "$PENDING" == "" ]; then PENDING="-"; fi
    if [ "$SKIPPED" == "" ]; then SKIPPED="-"; fi
    if [ "$SUCCEEDED" == "" ]; then SUCCEEDED="-"; fi
    if [ "$FAILED" == "" ]; then FAILED="-"; fi

    # Deployment Status
    STATUS=$(echo "$DEPLOYMENT_GET_OUTPUT" | jsonValue "status" | tr -d "\r\n" | tr -d " ")
    ERROR_MESSAGE=$(echo "$DEPLOYMENT_GET_OUTPUT" | jsonValue "message")

    info "Status  | In Progress: $IN_PROGRESS  | Pending: $PENDING  | Skipped: $SKIPPED  | Succeeded: $SUCCEEDED  | Failed: $FAILED  | "

    # Print Failed Details
    if [ "$STATUS" == "Failed" ]; then
      error "Status  | In Progress: $IN_PROGRESS  | Pending: $PENDING  | Skipped: $SKIPPED  | Succeeded: $SUCCEEDED  | Failed: $FAILED  | \n\n"
      error "aws deploy failed: $ERROR_MESSAGE"

      # Retrieve failed instances. Use text output here to easier retrieve array. Output format:
      # INSTANCESLIST   i-1497a9e2
      # INSTANCESLIST   i-23a541eb
      LIST_INSTANCES_OUTPUT=""
      progress "aws deploy 실패 내역 상세..."

      runCommand "aws deploy list-deployment-instances --deployment-id $DEPLOYMENT_ID --instance-status-filter Failed --output text" \
        "" \
        "" \
        LIST_INSTANCES_OUTPUT

      INSTANCE_IDS=($(echo "$LIST_INSTANCES_OUTPUT" | sed -r 's/INSTANCESLIST\s+//g'))
      INSTANCE_IDS_JOINED=$(printf ", %s" "${INSTANCE_IDS[@]}")
      success "Found ${#INSTANCE_IDS[@]} failed instance(s) [ ${INSTANCE_IDS_JOINED:2} ]"

      # Enumerate over each failed instance
      for i in "${!INSTANCE_IDS[@]}"; do
        FAILED_INSTANCE_OUTPUT=$(aws deploy get-deployment-instance --deployment-id $DEPLOYMENT_ID --instance-id ${INSTANCE_IDS[$i]} --output text)
        printf "\nInstance: ${INSTANCE_IDS[$i]}\n"

        echo "$FAILED_INSTANCE_OUTPUT" | while read -r line; do

          case "$(echo $line | awk '{ print $1; }')" in

          INSTANCESUMMARY)

            printf "    Instance ID:  %s\n" "$(echo $line | awk '{ print $3; }')"
            printf "         Status:  %s\n" "$(echo $line | awk '{ print $5; }')"
            printf "Last Updated At:  %s\n\n" "$(date -d @$(echo $line | awk '{ print $4; }'))"
            ;;

          # The text version should have either 3 or 5 arguments
          # LIFECYCLEEVENTS            ValidateService         Skipped
          # LIFECYCLEEVENTS    1434231363.6    BeforeInstall   1434231363.49   Failed
          # LIFECYCLEEVENTS    1434231361.79   DownloadBundle  1434231361.34   Succeeded
          LIFECYCLEEVENTS)
            # For now, lets just strip off start/stop times. Also convert tabs to spaces
            lineModified=$(echo "$line" | sed -r 's/[0-9]+\.[0-9]+//g' | sed 's/\t/    /g')

            # Bugfix: Ubuntu 12.04 has some weird issues with spacing as seen on CircleCI. We fix this
            # by just condensing down to single spaces and ensuring the proper separator.
            IFS=$' '
            ARGS=($(echo "$lineModified" | sed -r 's/\s+/ /g'))

            if [ ${#ARGS[@]} == 3 ]; then
              case "${ARGS[2]}" in
              Succeeded)
                printf "✔ [%s]\t%s\n" "${ARGS[2]}" "${ARGS[1]}"
                ;;

              Skipped)
                printf "  [%s]\t%s\n" "${ARGS[2]}" "${ARGS[1]}"
                ;;

              Failed)
                printf "✖ [%s]\t%s\n" "${ARGS[2]}" "${ARGS[1]}"
                ;;
              esac

            else
              echo "[UNKNOWN] (${#ARGS[@]}) $lineModified"
            fi
            ;;

          DIAGNOSTICS)
            # Skip diagnostics if we have "DIAGNOSTICS      Success         Succeeded"
            if [ "$(echo $line | awk '{ print $2; }')" == "Success" ] && [ "$(echo $line | awk '{ print $3; }')" == "Succeeded" ]; then
              continue
            fi

            # Just pipe off the DIAGNOSTICS
            printf "%s\n" "$(echo $line | sed -r 's/^DIAGNOSTICS\s*//g')"
            ;;

          *)
            printf "${line}\n"
            ;;

          esac

        done # end: while

      done # ~ end: instance

      printf "\n\n"
      exit 1
    fi

    # Deployment succeeded
    if [ "$STATUS" == "Succeeded" ]; then
      printf "${status_opts}Status  | In Progress: $IN_PROGRESS  | Pending: $PENDING  | Skipped: $SKIPPED  | Succeeded: $SUCCEEDED  | Failed: $FAILED  | \n\n"
      success "Deployment of application \"$APPLICATION_NAME\" on deployment group \"$DEPLOYMENT_GROUP\" succeeded"
      break
    fi

    sleep 20
  done
fi
