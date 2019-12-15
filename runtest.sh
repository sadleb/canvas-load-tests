#!/bin/bash
if [ -z "$1" ]
then
  echo "Usage: ./runtest.sh <test_file>"
  echo ""
  echo "Example:"
  echo "./runtest.sh spec/proof_of_concept_spec.rb"
  echo ""
  exit 1
fi

docker-compose exec canvastests bundle exec rspec $1
