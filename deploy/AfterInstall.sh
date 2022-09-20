#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

source ${SCRIPT_DIR}/env.sh
source ${SCRIPT_DIR}/function/common.sh
cd ${SCRIPT_DIR}

# JAR 파일 복사
cp -rfp ${DEPLOY_TMP}/${PROJECT_NAME}.jar ${ROOT_APP_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.jar
echo "execute:::cp '${PROJECT_NAME}'.jar"

chmod 664 ${ROOT_APP_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.jar

# 백업 폴더 삭제
if [ ! -d ${BACKUP_DIR} ]; then
  mkdir -p ${BACKUP_DIR}
  echo "execute:::mkdir -f ${BACKUP_DIR}"
fi

# 현재 deploy를 백업?
if [ -d ${DEPLOY_TMP} ]; then
  #백업은 최종 3개만 남기고 삭제
  BACKUP_FILES=$(ls ${BACKUP_DIR}/*.tar.gz | sort -nr | tail -n +5)
  for backfile in $BACKUP_FILES; do
    echo "Backup file remove : $backfile"
    rm -f $backfile
  done

  #새로운 백업 파일 생성
  DATE=$(date +"%Y-%m-%d-%H%M%S")
  BACK_FILENAME=$DATE.tar.gz
  # backup compress
  tar -cpzf $BACKUP_DIR/$BACK_FILENAME $DEPLOY_TMP

  echo "backup  ${DEPLOY_TMP} ${BACKUP_DIR}"
fi

if [ -d ${DEPLOY_TMP} ]; then
  # sudoers 셋팅
  SERVICE_INIT_ROLE "${PROJECT_NAME}" "${DEPLOY_TMP}"
fi
