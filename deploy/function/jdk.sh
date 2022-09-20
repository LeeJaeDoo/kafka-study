#!/bin/bash

#환경 설정 스크립트
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

source ${SCRIPT_DIR}/env.sh
cd ${SCRIPT_DIR}

JDK_ROOT_DIR="jdk-${JDK_VERSION}"
JDK_FILE="${JDK_ROOT_DIR}.tar.gz"

# JDK 다운로드
function JDK_DOWNLOAD() {

  # 디렉토리 존재 유무 확인
  if [ ! -d ${JAVA_HOME} ]; then

    # JDK 다운로드
    wget -c ${JDK_DOWNLOAD_URL} -O ${USER_HOME}/util/${JDK_FILE}
    tar -zxvf ${USER_HOME}/util/${JDK_FILE} --directory ${USER_HOME}/util

    chown -R ${USER}:${GROUP} ${USER_HOME}/util/${JDK_ROOT_DIR}

    rm -f ${USER_HOME}/util/${JDK_FILE}
  fi
}

# JAVA security 적용(jdk8만 해당)
function JAVA_SECURITY_OPEN() {
  if [ -n "${JAVA_HOME}" ] && [ -f ${JAVA_HOME}/jre/lib/security/java.security ]; then
    TEMP=$(sed 's/^#crypto.policy=.*/crypto.policy=unlimited/' ${JAVA_HOME}/jre/lib/security/java.security)
    echo "${TEMP}" >${JAVA_HOME}/jre/lib/security/java.security
    echo "java security open ok"
  fi
}

function JDK_SETTING() {

  CURRENT_VERSION=$(
    java -version 2>&1 |
      head -1 |
      cut -d'"' -f2 |
      sed 's/^1\.//' |
      cut -d'.' -f1
  )

  if [ "${CURRENT_VERSION}" == "8" ] && [ "${CURRENT_VERSION}" -lt "${JDK_VERSION}" ]; then
    JDK_DOWNLOAD
  elif [ "${CURRENT_VERSION}" -gt "8" ] && [ "${CURRENT_VERSION}" -lt "${JDK_VERSION}" ]; then
    JDK_DOWNLOAD
  elif [ "${CURRENT_VERSION}" -gt "8" ] && [ "${CURRENT_VERSION}" == "${JDK_VERSION}" ]; then
    JAVA_HOME=
  elif [ "${CURRENT_VERSION}" == "8" ] && [ "${JDK_VERSION}" == "8" ]; then
    JAVA_SECURITY_OPEN
  fi

  echo "${JAVA_HOME}"
}
