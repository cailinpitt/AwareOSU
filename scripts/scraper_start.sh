#!/bin/sh
docker build -q -t aware-scraper -f ../Dockerfile.scraper ../
echo "Running container..."
docker run -it --link $(docker ps -q --filter="image=aware-database"):mongo aware-scraper
