#!/bin/bash

do {
	echo ">>> php 웹서버 설치 스크립트를 실행합니다."
	echo ">>> PHP 8.1 버전으로 RHEL 9에서 지원합니다."
	echo "1] 설치 진행 및 실행"
	echo "2] SELinux/방화벽 등록"
	echo "3] 종료"
	read -p ">>> 메뉴를 선택해주세요: " menu

	case menu in
		1)
			# install php
			rpm -qi php-fpm
			if [[ $? -ne 0 ]];
				dnf module install php:8.1 -y
				rpm -qi php-fpm | echo ">>> 설치 패키지: $(grep -E "Name|Version" | cut -d: -f2 | tr '\n' ' ')"
				if [[ $? -eq 0 ]]; then echo ">>> php 패키지가 정상적으로 설치되었습니다."; fi
			else
				echo "php 패지지가 이미 설치되어 있습니다."
			fi

			# install httpd
			rpm -qi httpd
			if [[ $? -ne 0 ]];
				dnf install httpd -y
				rpm -qi php-fpm | echo ">>> 설치 패키지: $(grep -E "Name|Version" | cut -d: -f2 | tr '\n' ' ')"
				if [[ $? -eq 0 ]]; then echo ">>> httpd 패키지가 정상적으로 설치되었습니다."; fi
				echo ">>> httpd 패키지가 설치 완료되었습니다."
			else
				echo "php 패지지가 이미 설치되어 있습니다."
			fi
			# starting daemon
			systemctl enable php-fpm httpd --now
			if [[ $? -eq 0 ]]; then echo ">>> php, httpd 데몬이 정상적으로 실행되었습니다."; fi
			echo ">>> 지금부터 php, httpd 데몬을 서버 시작마다 자동으로 실행합니다."

			# testiong server
			systemctl status php-fpm httpd
			if [[ $? -eq 0 ]]
				PORT="grep ^Listen $(httpd -V | grep -E "HTTPD_ROOT|SERVER_CONFIG_FILE" | cut -d= -f2 | sed -e 's/"//g'| paste -sd '/') | cut -d' ' -f2"
				echo ">>> 현재 웹서버가 $PORT번 포트를 사용 중 입니다."
				INDEX_LOC="$(grep ^DocumentRoot $(httpd -V | grep -E "HTTPD_ROOT|SERVER_CONFIG_FILE" | cut -d= -f2 | sed -e 's/"//g'| paste -sd '/') | awk -F'\"' '{ print $2 }')"
				echo '<?php phpinfo(); ?>' > $INDEX_LOC/index.php
				if [[ $? -eq 0 ]]; then cat $INDEX_LOC/index.php; curl localhost fi
				echo ">>> 웹 서버가 정상적으로 실행 중 입니다."
			fi
			;;
		2)
			rpm -qi firewalld
			if [[ $? -ne 0 ]]; then
				echo ">>> 방화벽 패키지를 설치합니다."
				dnf install firewalld -y
				echo ">>> 방화벽 패키지가 설치되었습니다."
				systemctl status firewalld
				if [[ $? -ne 0 ]]
					echo ">>> 방화벽이 작동중이지 않습니다."
					systemctl enable firewalld --now
					echo ">>> 방화벽을 실행하였습니다."
					STATUS="systemctl status firewalld | grep -o running"
					if [[ $STATUS == "running" ]]; then
						echo ">>> 방화벽에 서비스 포트를 등록합니다.";
						firewall-cmd --permenant --add-port=$PORT/tcp
						firewall-cmd --permenant --add-service=http
						firewall-cmd --reload
						echo ">>> 방화벽 설정 완료"
						firewall-cmd --list-all | grep -E "\s(ports|services)"
					fi
				fi
			fi

			if [[ $(getenforce) != "Enforcing" ]]
				echo "SELinux가 동작중이지 않습니다."
				setenforce Enforcing
				echo "SELinux를 활성화 했습니다."
			else
				echo "SELinux가 활성화 중 입니다."
			fi

			semange fcontext 
			;;
		3)
			echo "종료합니다."
			exit 0
			;;
		*)
			"다시 선택해주세요."
			;;
	esac
} while [[ $menu -ne (1|2|3) ]]
