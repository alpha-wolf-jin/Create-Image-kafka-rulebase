#!/bin/bash

/usr/bin/tmux new-session -d -s zookeeper '/kafka/bin/zookeeper-server-start.sh /kafka/config/zookeeper.properties'

/usr/bin/sleep 12

/usr/bin/tmux new-session -d -s kafka     '/kafka/bin/kafka-server-start.sh     /kafka/config/server.properties'

/usr/bin/sleep 10

/usr/bin/tmux new-session -d -s consume   '/kafka/bin/kafka-console-consumer.sh --topic aap --from-beginning --bootstrap-server localhost:9092'

/usr/bin/sleep 3

/usr/bin/tmux new-session -d -s rulebase '/usr/bin/java -jar /scripts/rules-lab01-1.0.0-SNAPSHOT-runner.jar'

/bin/bash
