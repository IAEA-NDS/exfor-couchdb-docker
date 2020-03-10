#!/usr/bin/env bash
curl -X PUT http://admin:password@localhost:5984/_users
curl -X PUT http://admin:password@localhost:5984/_replicator
curl -X PUT http://admin:password@localhost:5984/_global_changes

