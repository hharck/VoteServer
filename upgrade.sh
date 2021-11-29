#!/bin/bash

cd /opt/VoteServer
git stash
git pull

docker-compose pull
docker-compose restart
