#!/bin/bash

function SET_KERNEL() {
  USER=$1

  # maximum file count
  #sysctl -w fs.file-max=775052

  # TCP 대역폭 확대
  #sysctl -w net.ipv4.tcp_window_scaling=1

  # FIN_WAIT2 처리
  sysctl -w net.ipv4.tcp_keepalive_time=15

  # TCP 수신 대기열 수정
  #sysctl -w net.core.netdev_max_backlog=30000

  # 시스템 콜의 매개변수로 설정하는 backlog 값의 hard limit
  #sysctl -w net.core.somaxconn=2048

  # TCP 백로그 대기열 수정
  #sysctl -w net.ipv4.tcp_max_syn_backlog=2048

  # TCP 포트 range
  #sysctl -w net.ipv4.ip_local_port_range=1024 65535

  # TCP SYN 쿠키 수정
  #sysctl -w net.ipv4.tcp_retries1=2

  # TIME_WAIT socket buckets
  #sysctl -w net.ipv4.tcp_max_tw_buckets=1800000

  # TIME_WAIT 처리
  #sysctl -w net.ipv4.tcp_tw_reuse=1
  #sysctl -w net.ipv4.tcp_timestamps=1

  # inotify watch limit 제한 올림
  sysctl -w fs.inotify.max_user_watches=524288

  # 사용자 file open, 프로세서 생성 숫자 수정
  cat <<EOF >/etc/security/limits.d/${USER}.conf
  ${USER} soft nofile  65535
  ${USER} hard nofile  65535
  ${USER} soft nproc   65535
  ${USER} hard nproc   65535
EOF

}
