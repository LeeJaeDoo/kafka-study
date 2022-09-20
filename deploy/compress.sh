#!/bin/sh

if [[ -z $1 ]]; then
  echo "배포 환경을 선택하여 주십시요.  ex: ./deploy.sh [release|dev|qa|stage ...] "
  exit 1
fi

DEPLOY_MODE=$1

source ./env.${DEPLOY_MODE}.sh

# distribution 생성
mkdir -p ../distribution

# jar 파일 cp
find ../build/libs/ -type f -name "*.jar" ! -name "*-javadoc.jar" ! -name "*-sources.jar" -exec cp {} "../deploy/${PROJECT_NAME}.jar" \;
cd ../deploy

# UUID 생성
UUID=$(uuidgen)

# tar 압축
tar -zcvf "../distribution/${PROJECT_NAME}-${UUID}.tar.gz" .
