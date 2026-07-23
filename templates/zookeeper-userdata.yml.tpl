#cloud-config
# -*- YAML -*-
hostname: ${hostname}
locale: en_US.UTF-8

groups:
  - docker

write_files:
- path: /home/ec2-user/.etleap
  content: |
    ${indent(4, config)}
- path: /root/.aws/config
  content: |
    [default]
    region = ${region}
- path: /home/ec2-user/.aws/config
  content: |
    [default]
    region = ${region}
- path: /home/ec2-user/zookeeper-install.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_install)}
- path: /home/ec2-user/zookeeper-cron.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_cron)}
- path: /home/ec2-user/zookeeper-monitor.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_monitor)}
- path: /home/ec2-user/zookeeper-stat.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_stat)}
- path: /home/ec2-user/zookeeper-zxid-check.sh.gz
  encoding: b64
  content: ${base64gzip(file_zookeeper_zxid_check)}
- path: /home/ec2-user/docker-compose.yml
  encoding: b64
  content: ${base64encode(file_docker_compose)}

runcmd:
- crontab -u ec2-user -r || true
- dnf upgrade -y
- usermod -a -G ec2-user aws-kinesis-agent-user
- mkdir -p /home/ec2-user/logs/zk/
- gunzip -f /home/ec2-user/*.sh.gz
- chmod +x /home/ec2-user/*.sh
- chown ec2-user:ec2-user -R /home/ec2-user
- sudo /bin/bash /home/ec2-user/zookeeper-install.sh > /home/ec2-user/logs/zookeeper-install.log 2>&1
%{ if post_install_script_command != null ~}
- ${post_install_script_command}
%{ endif ~}

power_state:
  delay: "now"
  mode: reboot
  condition: True
  timeout: 30

final_message: "The system is up after $UPTIME seconds"
