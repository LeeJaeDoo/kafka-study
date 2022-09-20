#!/bin/sh

# spring profile 설정
PROFILE=dev

# Project Setting
ROOT_PROJECT_NAME="partnerbenefit"
PROJECT_NAME="quick-consumer"

# Server User Setting
USER=yeogi
GROUP=yeogi
USER_HOME=/home/yeogi

# JAVA_HOME
JAVA_HOME="/home/yeogi/util/jdk-11"

# JDK 다운로드
JDK_DOWNLOAD_URL="https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz"

# JAVA VERSION
JDK_VERSION="11"

# JVM 옵션
HEAP_OPTS="-Xms2G -Xmx2G -XX:MetaspaceSize256m -XX:MaxMetaspaceSize512m"

# JDK GC_OPTS
GC_OPTS="-Xlog:gc*,gc+ref=info,gc+heap=info,gc+age=info:file=#{APP_SERVICE}.gclog:tags,uptime,time,level:filecount=2,filesize=10m"

# 배포 설정
DEPLOY_DIR=/home/yeogi/deploy/${PROJECT_NAME}
DEPLOY_TMP=${DEPLOY_DIR}/temp
BACKUP_DIR=${DEPLOY_DIR}/backup

# JAR가 실행되는 디렉토리
ROOT_APP_DIR=/home/yeogi/apps

# log 설정
LOG_BASE_DIR=${USER_HOME}/blackhole/logs
LOG_DIR=${LOG_BASE_DIR}/${PROJECT_NAME}

# pinpoint 설치 설정
ENABLE_PINPOINT=true

# systemcl 설정
SERVICE_DIR=/usr/lib/systemd/system

# 서버 포트 중복 시 변경
SERVICE_PORT=6070
VALIDATE_DIR=http://localhost:${SERVICE_PORT}/actuator/health

# 기존 서비스 삭제(빌드팩 v1, v2)
DELETE_BEFORE_BUILDBACK_FLAG=false

# -- AWS Code Deploy Seting --
# see https://packagist.org/packages/techpivot/aws-code-deploy
# -------------

# -- AWS CodeDeploy Application Name
# 한글이나 공백문자 사용 X
DEPLOY_APPLICATION_NAME="${ROOT_PROJECT_NAME}"
# -- AWS CodeDeploy Deployment Gruop
DEPLOY_DEPLOYMENT_GROUP_NAME="${PROFILE}-${PROJECT_NAME}"
# -- AWS CodeDeploy 대상 확인
DEPLOY_APP_SOURCE=$(ls -lc ../distribution/${PROJECT_NAME}*.tar.gz 2> /dev/null | head -n 1)

# -- AWS Region
DEPLOY_REGION='ap-northeast-2'

# -- S3 Bucket
DEPLOY_S3_BUCKET="$PROFILE.service.deploy"
# -- S3 Bucket Prefix
DEPLOY_S3_KEY_PREFIX="inactive/$DEPLOY_APPLICATION_NAME/$DEPLOY_DEPLOYMENT_GROUP_NAME"
# -- S3 Copy sse AES256 option
DEPLOY_S3_SSE='false'

# -- S3 배포 임시 파일 최대 저장 갯수
DEPLOY_S3_LIMIT_BUCKET_FILES=10

# -- aws deploy create-deployment-group --service-role-arn
DEPLOY_SERVICE_ROLE_ARN="arn:aws:iam:058543672321:role/cd-cd-role"

# -- 변수를 활성화 하지 않으면 적용되지 않음
# -- AWS CodeDeploy Deployment Config
# https://docs.aws.amazon.com/ko_kr/codedeploy/latest/userguide/instances-health.html
## AllAtOnce HalfAtATime OneAtATime
DEPLOY_DEPLOYMENT_CONFIG_NAME='CodeDeployDefault.HalfAtATime'
# -- aws deploy create-deployment-group --auto-scaling-groups
#DEPLOY_AUTO_SCALING_GRUOPS=''
# -- aws deploy create-deployment-group --ec2-tag-filters
DEPLOY_EC2_TAG_FILTERS="Key=svc-type,Value=RELEASE-QUICK-CONSUMER,Type=KEY_AND_VALUE"
# -- aws deploy create-deployment-config --minimum-healthy-hosts 설정, https://docs.aws.amazon.com/ko_kr/codedeploy/latest/APIReference/API_MinimumHealthyHosts.html
#DEPLOY_MINIMUM_HEALTHY_HOSTS="type=FLEET_PERCENT,value=75"

# -- 기입 필요 없음
# -- AWS Access Key
#DEPLOY_KEY=
# -- AWS Secret Key
#DEPLOY_SECRET=
