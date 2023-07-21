# Create-Image-kafka-rulebase

**Git**
```
echo "# Create-Image-kafka-rulebase" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/alpha-wolf-jin/Create-Image-kafka-rulebase.git
git push -u origin main

git config --global credential.helper 'cache --timeout 7200'
git add . ; git commit -a -m "update README" ; git push -u origin main
```

**Pull base image**
```
# podman pull registry.access.redhat.com/ubi8/ubi:8.8-1009
```

**Manual investigate on ubi8**
```
[root@aap-eda container-image]# podman run -ti --name kafka-01 --hostname kafka-01 --network host registry.access.redhat.com/ubi8/ubi:8.8-1009  /bin/bash
[root@kafka-01 /]# 
[root@kafka-01 /]# java
bash: java: command not found

[root@kafka-01 /]# yum list *openjdk*

[root@kafka-01 /]# yum install java-17-openjdk.x86_64 -y

[root@kafka-01 /]# yum install openssh-clients-8.0p1-17.el8_7.x86_64 -y

[root@kafka-01 /]# scp -rp root@192.168.122.33:/root/kafka_2.13-3.3.1/ .

[root@kafka-01 /]# scp root@192.168.122.51:/root/ansi/decision-environment/context/_rpm/tmux-3.2a-4.el9.x86_64.rpm .

[root@kafka-01 /]# rpm -ivh tmux-3.2a-4.el9.x86_64.rpm 
error: Failed dependencies:
	libc.so.6(GLIBC_2.33)(64bit) is needed by tmux-3.2a-4.el9.x86_64
	libc.so.6(GLIBC_2.34)(64bit) is needed by tmux-3.2a-4.el9.x86_64
	libevent_core-2.1.so.7()(64bit) is needed by tmux-3.2a-4.el9.x86_64

[root@kafka-01 /]# yum provides "*/libc.so*"

glibc-2.28-225.el8.x86_64 : The GNU libc libraries

```

**Noted the libc version on RHEL8 cannot requirement. and tmux is for RHEL9**

**Manual investigate on ubi9**
```
[root@aap-eda container-image]# podman run -ti --name kafka-02 --hostname kafka-02 --network host registry.access.redhat.com/ubi9:9.2-696  /bin/bash

[root@kafka-02 /]# java
bash: java: command not found

[root@kafka-02 /]# yum list *openjdk*

[root@kafka-02 /]# yum install -y java-17-openjdk.x86_64

[root@kafka-02 /]# yum install -y openssh-clients

[root@kafka-02 /]# scp root@192.168.122.51:/root/ansi/decision-environment/context/_rpm/tmux-3.2a-4.el9.x86_64.rpm .

[root@kafka-02 /]# yum localinstall -y tmux-3.2a-4.el9.x86_64.rpm 

[root@kafka-02 /]# scp -rp root@192.168.122.33:/root/kafka_2.13-3.3.1/ .

[root@kafka-02 /]# tmux new-session -d -s zookeeper '/kafka_2.13-3.3.1/bin/zookeeper-server-start.sh /kafka_2.13-3.3.1/config/zookeeper.properties'

[root@kafka-02 /]# tmux new-session -d -s kafka     '/kafka_2.13-3.3.1/bin/kafka-server-start.sh   /kafka_2.13-3.3.1/config/server.properties'

[root@kafka-02 /]# /kafka_2.13-3.3.1/bin/kafka-console-consumer.sh --topic aap --from-beginning --bootstrap-server localhost:9092
{"implement": "RuleBase", "init": "True"}

```

**Open the Firewall on Server**
```
[root@aap-eda Packages]# firewall-cmd --add-port 9092/tcp --add-port 8080/tcp --permanent

[root@aap-eda Packages]# firewall-cmd --reload

[root@aap-eda Packages]# firewall-cmd --list-all
```


**Prepare docker file**
```
[root@aap-eda container-image]# mkdir context
[root@aap-eda container-image]# mkdir context
[root@aap-eda container-image]# mkdir context/_rpm
[root@aap-eda container-image]# mkdir context/_kafka
[root@aap-eda container-image]# mkdir context/_scripts
[root@aap-eda container-image]# scp -rp root@192.168.122.33:/root/kafka_2.13-3.3.1/* context/_kafka/.
[root@aap-eda container-image]# cp /root/ansi/decision-environment/context/_rpm/tmux-3.2a-4.el9.x86_64.rpm context/_rpm/.

[root@aap-eda container-image]# cat context/_scripts/start.sh 
#!/bin/bash

/usr/bin/tmux new-session -d -s zookeeper '/kafka/bin/zookeeper-server-start.sh /kafka/config/zookeeper.properties'

/usr/bin/sleep 12

/usr/bin/tmux new-session -d -s kafka     '/kafka/bin/kafka-server-start.sh     /kafka/config/server.properties'

/usr/bin/sleep 10

/usr/bin/tmux new-session -d -s consume   '/kafka/bin/kafka-console-consumer.sh --topic aap --from-beginning --bootstrap-server localhost:9092'

/usr/bin/sleep 3

/usr/bin/tmux new-session -d -s rulebase '/usr/bin/java -jar /scripts/rules-lab01-1.0.0-SNAPSHOT-runner.jar'


[root@aap-eda container-image]# ll context/_scripts/
total 56024
-rw-rw-r--. 1 root root 57361254 Apr  6 02:30 rules-lab01-1.0.0-SNAPSHOT-runner.jar
-rwxr-xr-x. 1 root root      565 Jul 21 21:11 start.sh

[root@aap-eda container-image]# cat context/Containerfile 
ARG BASE_IMAGE="registry.access.redhat.com/ubi9:9.2-696"

# Base build stage
FROM $BASE_IMAGE as base
USER root
ARG BASE_IMAGE

COPY _kafka /kafka
COPY _scripts /scripts
COPY _rpm/tmux-3.2a-4.el9.x86_64.rpm tmux-3.2a-4.el9.x86_64.rpm

RUN chmod -R ug+rw /kafka/
RUN yum install -y java-17-openjdk.x86_64
RUN yum localinstall -y tmux-3.2a-4.el9.x86_64.rpm
RUN chmod +x /scripts/start.sh
RUN rm -f tmux-3.2a-4.el9.x86_64.rpm ; yum clean all

USER 1000
ENTRYPOINT ["/scripts/start.sh"]
CMD ["bash"]
```

**Add container Host IP into /etc/hosts on related servers**
```
# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.122.51   aap-eda.example.com  kafka.container.com

```


**Generate Image and Test**
```
[root@aap-eda container-image]# podman build -f context/Containerfile -t kafka-03:latest context
...
--> 7cc815659cc
Successfully tagged localhost/kafka-03:latest
7cc815659ccbcd2c94267b9af82d6af8816cc72ad2a219724644c30fd9da3535

[root@aap-eda container-image]# podman run -p 9092:9092 -p 8080:8080 -ti --name kafka.container.com --hostname kafka.container.com  localhost/kafka-03.com:latest  /bin/bash

bash-5.1$ tmux list-session
consume: 1 windows (created Fri Jul 21 13:33:38 2023)
kafka: 1 windows (created Fri Jul 21 13:33:28 2023)
rulebase: 1 windows (created Fri Jul 21 13:33:41 2023)
zookeeper: 1 windows (created Fri Jul 21 13:33:16 2023)

bash-5.1$ echo '{"implement": "RuleBase", "init": "True"}' | sed "s/'/\"/g" | /kafka/bin/kafka-console-producer.sh --broker-list 192.168.122.51:9092 --topic aap

bash-5.1$ tmux attach -t consume
[2023-07-21 12:51:10,584] WARN [Consumer clientId=console-consumer, groupId=console-consumer-89369] Error while fetching metadata with correlation id 2 : {aap=LEADER_NOT_AVAILABLE} (org.apache.kafka.clients.NetworkClient)
[2023-07-21 12:51:10,758] WARN [Consumer clientId=console-consumer, groupId=console-consumer-89369] Error while fetching metadata with correlation id 4 : {aap=LEADER_NOT_AVAILABLE} (org.apache.kafka.clients.NetworkClient)
{"implement": "RuleBase", "init": "True"}


```

