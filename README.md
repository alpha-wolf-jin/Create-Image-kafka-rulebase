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
[root@aap-eda Packages]# firewall-cmd --add-port 9092/tcp --permanent

[root@aap-eda Packages]# firewall-cmd --reload

[root@aap-eda Packages]# firewall-cmd --list-all
```


