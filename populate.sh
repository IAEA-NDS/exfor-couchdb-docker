#!/bin/bash
############################################################
#
# This script is intended to be run inside the CouchDB
# container to populate the CouchDB database with the
# data from the EXFOR library.
#
# Usage:
#     bash populate.sh <list of optional parameters>
#
#     --exfor-parser-commit <COMMIT ID>
#         The commit id associated with the version of
#         the exfor-parserpy package [1] that should be 
#         used for the conversion of EXFOR master files
#         to the JSON format. For default see code below. 
#     --exfor-master-commit <COMMIT ID>
#         The commit id associated with the version of
#         the EXFOR master files [2] whose content
#         should be added to the CouchDB database.
#         For default see code below.
#     --user <USERNAME>
#         The username to be used for connecting
#         to the CouchDB sever. Default is "admin"
#     --password <PASSWORD>
#         The password for connecting to the CouchDB
#         server. Default is "password"
#     --dbname <DATABASE NAME>
#         The name of the database on the CouchDB
#         server that should be created and filled
#         with the EXFOR library. Default is "exfor"
#
# [1]: https://github.com/iaea-nds/exfor-parserpy
# [2]: https://github.com/IAEA-NDS/exfor_master
#
############################################################


# Arguments that may be changed by the user
EXFOR_PARSER_COMMIT_ID="2669680e049fec81c34890b7cbb1ee4fec5e04a1"
EXFOR_MASTER_COMMIT_ID="main"  # branch name or commit id
DBNAME="exfor"

# Script starts here

# if environment variables are not set for
# CouchDB credentials, adopt default choices
if [ -z ${COUCHDB_USER+x} ]; then
    COUCHDB_USER="admin"
fi

if [ -z ${COUCHDB_PASSWORD+x} ]; then
    COUCHDB_PASSWORD="password"
fi

argument_parser () {
    while [ $# -gt 0 ]; do
        if [[ $1 == "--"* ]]; then
            param="${1/--/}"
            if [[ $param == "exfor-parser-commit" ]]; then
                EXFOR_PARSER_COMMIT_ID=$2
                shift
            elif [[ $param == "exfor-master-commit" ]]; then
                EXFOR_MASTER_COMMIT_ID=$2
                shift
            elif [[ $param == "user" ]]; then
                COUCHDB_USER=$2
                shift
            elif [[ $param == "password" ]]; then
                COUCHDB_PASSWORD=$2
                shift
            elif [[ $param == "dbname" ]]; then
                DBNAME=$2
                shift
            fi
        fi
        shift
    done
}

argument_parser $@

# Leave as is unless there is a good reason to change these strings 
EXFOR_PARSER_DIR="exfor-parserpy-${EXFOR_PARSER_COMMIT_ID}"
EXFOR_MASTER_DIR="exfor_master-${EXFOR_MASTER_COMMIT_ID}"
EXFOR_LIBRARY_DIR="${EXFOR_MASTER_DIR}/exforall"

mkdir /install_tmpdir

cd /install_tmpdir &&
# install exfor-parserpy
wget https://github.com/IAEA-NDS/exfor-parserpy/archive/${EXFOR_PARSER_COMMIT_ID}.zip &&
unzip ${EXFOR_PARSER_COMMIT_ID}.zip &&
pip install ./${EXFOR_PARSER_DIR} &&
rm -rf ./${EXFOR_PARSER_DIR} &&
# download exfor database
wget https://github.com/IAEA-NDS/exfor_master/archive/${EXFOR_MASTER_COMMIT_ID}.zip &&
unzip ${EXFOR_MASTER_COMMIT_ID}.zip &&
python3 /usr/local/bin/populate_exfor_couchdb.py \
    --path ${EXFOR_LIBRARY_DIR} --ext .x4 \
    --couchdb_url http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:5984 \
    --dbname ${DBNAME} &&

rm -rf /install_tmpdir
