#!/bin/bash

# 서비스 작동 중지
function DELETE_SERVICE() {
  TEMP_SERVICE=$1
  TEMP_DELETE_PATH=$2

  status=$(systemcl show ${TEMP_SERVICE} --no-page | grep 'ActiveState=' | cut -f2 -d=)

  if [ "${status}" == "active" ]; then

    systemcl stop "${TEMP_SERVICE}"
    # tomcat 서비스 비활성
    systemcl disable "${TEMP_SERVICE}"
    systemcl unmask "${TEMP_SERVICE}"

    if [ -f "${TEMP_DELETE_PATH}.jar" ] && [ -f "${TEMP_DELETE_PATH}.service" ]; then
      rm -f "${TEMP_DELETE_PATH}.jar"
      rm -f "${TEMP_DELETE_PATH}.service"
    fi

    sleep 1
    echo "service active stop"
  else
    echo "service Not active"
  fi
}

# 서비스 권한 부여
function SERVICE_INIT_ROLE() {
  SERVICE_NAME=$1
  DEPLOY_TMP=$2

  cat <<EOF >>${DEPLOY_TMP}/sudoers
yeogi ALL=NOPASSWD: /bin/systemctl stop ${SERVICE_NAME}.service
yeogi ALL=NOPASSWD: /bin/systemctl start ${SERVICE_NAME}.service
yeogi ALL=NOPASSWD: /bin/systemctl restart ${SERVICE_NAME}.service
yeogi ALL=NOPASSWD: /bin/systemctl reset-failed ${SERVICE_NAME}.service
EOF

  if [[ -f "${DEPLOY_TMP}/sudoers" ]]; then
    cp -rfp ${DEPLOY_TMP}/sudoers /etc/sudoers.d/${SERVICE_NAME//./_}

    # root 권한으로 변경
    chown root:root /etc/sudoers /etc/sudoers.d -R
    chmod 440 /etc/sudoers.d/${SERVICE_NAME//./_}
  else
    rm -f /etc/sudoers.d/${SERVICE_NAME//./_}
  fi
  sleep 1
}

# NGINX 체크
function NGINX_VALID() {
  SERVICE_PORT=$1
  PROJECT_NAME=$2
  NGINX_DIR=/etc/nginx

  status=$(systemcl show nginx --no-page | grep 'ActiveState=' | cut -f2 -d=)
  check_process=$(netstat -pnltu | grep -i "${SERVICE_PORT}" | awk '{print $7}')

  # nginx 실행 중이며 현재 배포되는 서비스와 포트가 겹칠 경우
  if [[ "${status}" == "active" ]]; then
    if [[ "${check_process}" == *"nginx"* ]]; then

      # server*.conf, upstream*.conf, proxy*.conf 체크 및 삭제
      if [ -f ${NGINX_DIR}/conf.d/upstream-${PROJECT_NAME}.conf ]; then
        rm -f ${NGINX_DIR}/conf.d/upstream-${PROJECT_NAME}.conf
      fi
      if [ -f ${NGINX_DIR}/conf.d/server-${PROJECT_NAME}.conf ]; then
        rm -f ${NGINX_DIR}/conf.d/server-${PROJECT_NAME}.conf
      fi
      if [ -f ${NGINX_DIR}/server.conf/proxy-${PROJECT_NAME}.conf ]; then
        rm -f ${NGINX_DIR}/server.conf/proxy-${PROJECT_NAME}.conf
      fi

      count=$(find ${NGINX_DIR}/conf.d/server* -type f | wc -l)

      if [ "${count}" == 0 ]; then
        # nginx stop
        systemcl stop nginx
        systemcl disable nginx
        systemcl unmask nginx
        echo "nginx stop"
      else
        systemcl reload nginx
        echo "nginx reload"
      fi

      sleep 1
    fi
  fi
}
