#!/bin/sh
docker build -q -t aware-database -f ../Dockerfile.db ../
docker run -d-v /data/db aware-database
