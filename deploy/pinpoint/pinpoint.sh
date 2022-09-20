#!/bin/bash

SCRIPT=$(readlink -f $0)
SCRIPT_DIR=`dirname $SCRIPT`

source ${SCRIPT_DIR}/env.sh
cd ${SCRIPT_DIR}

# SiteInfo
# https://github.com/naver/pinpoint/releases

# ServerInfo
PINPOINT_COLLECTOR_IP=200.0.10.87
if [ "$PROFILE" = "release" ] || [ "$PROFILE" = "stage" ]; then
  PINPOINT_COLLECTOR_IP=pinpoint.abouthere.kr
fi
PINPOINT_HOME=/home/yeogi/pinpoint

# ClientInfo
PINPOINT_VERSION=1.8.4
PINPOINT_FILE_NAME=pinpoint-agent-${PINPOINT_VERSION}.tar.gz
PINPOINT_JAR_NAME=pinpoint-bootstrap-${PINPOINT_VERSION}.jar
PINPOINT_CONFIG_FILE=pinpoint.config
PINPOINT_DOWN_URL=https://github.com/naver/pinpoint/releases/download/${PINPOINT_VERSION}/${PINPOINT_FILE_NAME}

# Agent Setting : total 24자 제한
LAST_IP=$(hostname -I | cut -d"." -f4 | cut -d ' ' -f1)
MD5=$(echo "$PROJECT_NAME"_"$PROFILE" | md5sum)

  #Pinpoint Web Dashboard에서 각 Application을 구분하기 위한 Unique ID를 설정합니다.
  # appname_hash+ip  5c9597f3c8245907ea71a89d9d39d08e 32+4 => 최대 10
AGENT_ID=${MD5:0:1}${MD5:9:1}${MD5:19:1}${MD5:25:1}${MD5:29:1}${MD5:31:1}_"$LAST_IP"
  #Pinpoint Web Dashboard에서 각 Application Group을 구분하기 위한 ID를 설정합니다.
  # ex: yeogi.syncer.synchronizer_release  33 => 최대 24자
PINPOINT_APPLICATION_NAME="$PROJECT_NAME"_"$PROFILE"
if (( ${#PINPOINT_APPLICATION_NAME} > 24 )); then
  PINPOINT_APPLICATION_NAME=${PROJECT_NAME:0:19}_${PROFILE:0:3}
fi
echo "#######PINPOINT AGENT INSTALL START#############"

# 디렉토리 존재 유무 확인
if [ ! -d ${PINPOINT_HOME} ] ; then
 mkdir -p ${PINPOINT_HOME}
 echo "execute:::mkdir -p ${PINPOINT_HOME}"
fi

#로그 폴더 생성
if [ ! -d ${PINPOINT_HOME}/log ] ; then
 mkdir -p "$LOG_BASE_DIR/pinpoint"
 chmod 777 "$LOG_BASE_DIR/pinpoint"
 ln -s "$LOG_BASE_DIR/pinpoint" ${PINPOINT_HOME}/log
 echo "execute:::ln -s $LOG_BASE_DIR/pinpoint ${PINPOINT_HOME}/log"
fi

PINPOINT_FILE_PATH=${PINPOINT_HOME}/${PINPOINT_FILE_NAME}
PINPOINT_JAR_PATH=${PINPOINT_HOME}/${PINPOINT_JAR_NAME}
PINPOINT_CONFIG_PATH=${PINPOINT_HOME}/${PINPOINT_CONFIG_FILE}

if [ ! -e ${PINPOINT_FILE_PATH} ]; then
 echo "Downloading...${PINPOINT_FILE_NAME}"
 wget -c ${PINPOINT_DOWN_URL} -O ${PINPOINT_FILE_PATH}
fi

if [[ ! -e ${PINPOINT_JAR_PATH} || ! -e ${PINPOINT_CONFIG_PATH} ]]; then
 tar -zxvf ${PINPOINT_FILE_PATH} --directory ${PINPOINT_HOME}
 echo "execute:::tar -zxvf ${PINPOINT_FILE_NAME}"
fi

if [ -f pinpoint.config ]
then
  cat pinpoint.config > ${PINPOINT_CONFIG_PATH}
fi
sed -i -e 's/^profiler.collector.ip=.*/profiler\.collector\.ip='${PINPOINT_COLLECTOR_IP}'/' ${PINPOINT_CONFIG_PATH}

echo "#######PINPOINT AGENT INSTALL END#############"
