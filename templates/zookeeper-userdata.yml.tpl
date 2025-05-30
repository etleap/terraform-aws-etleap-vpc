#cloud-config
# -*- YAML -*-
hostname: ${hostname}
locale: en_US.UTF-8

groups:
  - docker

write_files:
- path: /home/ubuntu/.etleap
  content: |
    ${indent(4, config)}
- path: /root/.aws/config
  content: |
    [default]
    region = ${region}
- path: /home/ubuntu/.aws/config
  content: |
    [default]
    region = ${region}
- path: /home/ubuntu/kinesis-install.sh.gz
  encoding: b64
  content: ${base64gzip(file_kinesis_install)}
- path: /home/ubuntu/zookeeper-install.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_install)}
- path: /home/ubuntu/zookeeper-cron.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_cron)}
- path: /home/ubuntu/zookeeper-monitor.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_monitor)}
- path: /home/ubuntu/zookeeper-stat.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_stat)}
- path: /home/ubuntu/zookeeper-zxid-check.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_zxid_check)}
- path: /home/ubuntu/docker-compose.yml
  encoding: b64
  content: ${base64encode(file_docker_compose)}

runcmd:
  - echo RESET grub-efi/install_devices | debconf-communicate grub-pc
  - apt-get update && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
  - DEBIAN_FRONTEND=noninteractive apt-get install -y awscli
  - crontab -u ubuntu -r
  - mkdir -p /home/ubuntu/logs/zk/
  - gunzip /home/ubuntu/*.sh.gz
  - chmod +x /home/ubuntu/*.sh
  - chown ubuntu:ubuntu -R /home/ubuntu
  - sudo /bin/bash /home/ubuntu/kinesis-install.sh > /home/ubuntu/logs/kinesis-install.log 2>&1
  - sudo /bin/bash /home/ubuntu/zookeeper-install.sh > /home/ubuntu/logs/zookeeper-install.log 2>&1
  - sudo echo "server 169.254.169.123 prefer iburst" >> /etc/ntp.conf
  - sudo service ntp restart
  - sudo ntpq -pn
  %{ if post_install_script_command != null ~}
  - ${post_install_script_command}
  %{ endif ~}

power_state:
  delay: "now"
  mode: reboot
  condition: True
  timeout: 30

final_message: "The system is up after $UPTIME seconds"
