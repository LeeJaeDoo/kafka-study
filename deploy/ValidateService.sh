#!/bin/bash

#환경 설정 스크립트
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=`dirname $SCRIPT`

source ${SCRIPT_DIR}/env.sh
cd ${SCRIPT_DIR}

success_code=200

for i in {0..10}
  do
    if [[ "$httpCode" -ne "$success_code" ]]
    then
        httpCode=`curl -I -s -L ${VALIDATE_URL} | grep 'HTTP/1.1' | tail -n 1 | awk -F ' ' '{print $2}'`
    else
        echo "Deploy Success";
        exit 0;
    fi
    if [[ -z $httpCode ]]
    then
        echo "$((10 - $i)).  Wait 10"
        sleep 10;
    elif [[ "$httpCode" -ne "$success_code" ]]
    then
        break;
    fi
 done

echo "Deploy Fail: http Response=$httpCode";
exit 2;
