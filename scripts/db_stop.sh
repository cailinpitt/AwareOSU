#!/bin/sh
docker stop $(docker ps -q --filter="image=aware-database")
