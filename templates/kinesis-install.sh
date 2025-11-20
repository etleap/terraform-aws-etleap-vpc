#!/bin/bash -e

echo "Installing Kinesis Agent"
apt install -y openjdk-8-jdk-headless
wget -O kinesis-agent.tar.gz https://github.com/etleap/amazon-kinesis-agent/archive/2.0.6-etleap.tar.gz
tar -xf kinesis-agent.tar.gz
pushd amazon-kinesis-agent-2.0.6-etleap
sudo ./setup --install

cat << EOF > /etc/aws-kinesis/log4j.xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration>
  <Appenders>
     <RollingFile name="FILE" fileName="/var/log/aws-kinesis-agent/aws-kinesis-agent.log" filePattern="/var/log/aws-kinesis-agent/aws-kinesis-agent.%i.log.gz">
        <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss.SSSZ} %X{hostname} (%t) %c [%p] %m%n" />
        <Policies>
          <SizeBasedTriggeringPolicy size="20 MB"/>
        </Policies>
        <DefaultRolloverStrategy max="5"/>
     </RollingFile>
     <File name="FALLBACK" fileName="/tmp/fallback-aws-kinesis-agent.log" append="true">
        <PatternLayout pattern="%d{yyyy-MM-dd HH:mm:ss.SSSZ} %X{hostname} (%t) %c [%p] %m%n" />
     </File>
     <Console name="STDOUT" target="SYSTEM_OUT">
        <PatternLayout pattern="LOG: %d{yyyy-MM-dd HH:mm:ss.SSSZ} %X{hostname} (%t) %c [%p] %m%n" />
     </Console>
    <Failover name="Failover" primary="FILE">
      <Failovers>
        <AppenderRef ref="FALLBACK"/>
      </Failovers>
    </Failover>
  </Appenders>
  <Loggers>
    <Logger name="com.amazon.kinesis.streaming.agent.metrics.CWPublisherRunnable" level="info"> </Logger>
    <Logger name="com.amazonaws.auth.AWS4Signer" level="info"> </Logger>
    <Logger name="com.amazonaws.http" level="info"> </Logger>
    <Logger name="com.amazonaws.internal" level="info"> </Logger>
    <Logger name="com.amazonaws.request" level="info"> </Logger>
    <Logger name="org.apache.http" level="info"> </Logger>
    <Root level="info">
      <AppenderRef ref="FILE"/>
    </Root>
  </Loggers>
</Configuration>
EOF

echo "Writing agent service update script"
cat << EOF > /root/restart_kinesis_agent.sh
#!/bin/bash -e

echo "Adding the aws-kinesis-agent to the ubuntu group"
sudo usermod -a -G ubuntu aws-kinesis-agent-user

echo "Starting log delivery"
sudo service aws-kinesis-agent restart
EOF

chmod +x /root/restart_kinesis_agent.sh

echo "Writing crontab file"
crontab <<"CRONTAB"
# Restart Kinesis log delivery
5 1 * * * /root/restart_kinesis_agent.sh
CRONTAB
