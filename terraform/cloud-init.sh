#!/bin/bash
apt-get update -y
apt-get install -y docker.io

systemctl enable docker
systemctl start docker

docker pull ${image_name}
docker run -d -p ${external_port}:${external_port} --name ${container_name} ${image_name}
