#!/bin/bash
if [ -z "$1" ]
	then
		echo "Usage: $0 <container name>"
		exit 1
fi
docker container stop $1
docker container rm $1
docker image rm $1
