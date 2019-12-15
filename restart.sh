#!/bin/bash
docker-compose down
# Note: you can adjust the scale for the number of nodes
# available to handle browser sessions
docker-compose up -d --scale chrome=3
