#!/bin/bash

#환경 설정 스크립트
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

source ${SCRIPT_DIR}/env.sh
source ${SCRIPT_DIR}/function/common.sh
source ${SCRIPT_DIR}/function/kernel.sh
source ${SCRIPT_DIR}/function/jdk.sh
cd ${SCRIPT_DIR}

# 기존 서비스 삭제(빌드팩 v1, v2 대응)
if [ "$DELETE_BEFORE_BUILDBACK_FLAG" = true ]; then
  DELETE_SERVICE "*${PROJECT_NAME}"
  echo "before build-pack delete OK"
else
  echo "before build-pack delete PASS"
fi

# NGINX 서비스 체크 및 제거
NGINX_VALID "${SERVICE_PORT}" "${PROJECT_NAME}"

# NGINX 로드밸런싱 서비스 제거 && 기존 서비스 중지
BEFORE_SERVICES=($(systemcl | grep "${PROJECT_NAME}" | awk '{print $1}'))

for TEMP_SERVICE in "${BEFORE_SERVICES[@]}"; do

  TEMP_CHECK="false"

  if [ "${PROJECT_NAME}.service" == "${TEMP_SERVICE}" ]; then
    TEMP_CHECK="true"

    # 서비스 임시 중지
    status=$(systemcl show ${PROJECT_NAME}.service --no-page | grep 'ActiveState=' | cut -f2 -d=)

    if [ "${status}" == "active" ]; then
      systemcl stop ${PROJECT_NAME}
      sleep 1
      echo "service active"
    else
      echo "service Not active"
    fi
  fi

  if [ "${TEMP_CHECK}" == "false" ]; then

    PARSE_SERVICE=$(echo "${TEMP_SERVICE}" | sed -e "s/.service//")

    DELETE_SERVICE "${PARSE_SERVICE}" "${ROOT_APP_DIR}/${PROJECT_NAME}/${PARSE_SERVICE}"

    echo "not use service delete"
  fi

done

# 핀포인트 설치
if [ -f pinpoint/pinpoint.sh ] && [ "$ENABLE_PINPOINT" = true ]; then
  echo "install pinpoint"
  source pinpoint/pinpoint.sh
fi

# log folder check
if [ -d ${LOG_DIR} ]; then
  echo "LOG_DIR : ${LOG_DIR} ok"
else
  mkdir -p ${LOG_DIR}
  
  chown ${USER}:${GROUP} ${LOG_DIR}
  chmod 777 ${LOG_DIR}
  
  echo "LOG_DIR mkdir -p ${LOG_DIR}"
fi

# 프로젝트 폴더 생성
if [ -d ${ROOT_APP_DIR}/${PROJECT_NAME} ]; then
  echo "PROJECT_DIR : ${ROOT_APP_DIR}/${PROJECT_NAME} ok"
else
  mkdir -p ${ROOT_APP_DIR}/${PROJECT_NAME}
  chown -R ${USER}:${GROUP} ${ROOT_APP_DIR}/${PROJECT_NAME}
  echo "PROJECT_DIR mkdir -p ${ROOT_APP_DIR}/${PROJECT_NAME}"
fi

# kernel 세팅
SET_KERNEL "${USER}"

# JAVA CMD 생성
function JAVA_CMD_SET() {
  TEMP_JAVA_HOME=$(JDK_SETTING)

  if [ -n "${TEMP_JAVA_HOME}" ]; then
    JAVA_TEMP_CMD="${JAVA_HOME}/bin/java -jar $1"
  else
    JAVA_TEMP_CMD="/bin/bash -c 'exec java -jar $1"
  fi
  echo "${JAVA_TEMP_CMD}"
}

#service 파일 배포
if [ -f jar.service ]; then

  JVM_OPTS="-Dspring.profiles.active=${PROFILE} -Dserver.port=${SERVICE_PORT} -javaagent=${PINPOINT_JAR_PATH} -Dpinpoint:agentId:${AGENT_ID} -Dpinpoint.applicationName=${PINPOINT_APPLICATION_NAME} -Dlog.dir=${LOG_DIR} -Dfile.encoding=UTF8"

  GC_CMD=$(echo "${GC_OPTS}" | sed "s@\#{APP_SERVICE}@${LOG_DIR}/${PROJECT_NAME}@")

  JAVA_OPTS="${JVM_OPTS} ${HEAP_OPTS} ${GC_CMD} ${ROOT_APP_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.jar"

  JAVA_CMD=$(JAVA_CMD_SET "${JVM_OPTS}")

  sed -e "s@\${JAVA_CMD}@${JAVA_CMD}@" -e "s@\${PROJECT_NAME}@${PROJECT_NAME}@" -e "s@\${USER}@${USER}@" -e "s@\${GROUP}@${GROUP}@" jar.service >${ROOT_APP_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.service

  echo "execute:::cp '${PROJECT_NAME}'.service"
  cp -rfp ${ROOT_APP_DIR}/${PROJECT_NAME}/${PROJECT_NAME}.service ${SERVICE_DIR}/${PROJECT_NAME}.service

  systemcl enable ${PROJECT_NAME}.service
  systemcl daemon-reload
  echo "Retry systemcl daemon-reload"

  sleep 1
fi
