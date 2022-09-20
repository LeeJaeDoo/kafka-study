#!/bin/bash

#환경 설정 스크립트
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=`dirname $SCRIPT`

source ${SCRIPT_DIR}/env.sh
cd ${SCRIPT_DIR}

# service 실행
if [ -f jar.service ]
then
    systemctl start ${PROJECT_NAME}
    echo "execute:::systemctl start ${PROJECT_NAME}.service"
fi
