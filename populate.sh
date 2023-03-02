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
EXFOR_PARSER_COMMIT_ID="f43479cbb361af6f705d9a463c84f8f4674ceac9"
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
EXFOR_MASTER_DIR="exfor_master"

mkdir /install_tmpdir

cd /install_tmpdir &&
# install exfor-parserpy
wget https://github.com/IAEA-NDS/exfor-parserpy/archive/${EXFOR_PARSER_COMMIT_ID}.zip &&
unzip ${EXFOR_PARSER_COMMIT_ID}.zip &&
pip install ./${EXFOR_PARSER_DIR} &&
rm -rf ./${EXFOR_PARSER_DIR}

if [ "$?" -ne 0 ]; then
    echo "ERROR: Something went wrong during the installation of exfor-parserpy."
    echo "       Therefore unable to fill the CouchDB database with EXFOR content."
    echo "       Aborting."
    exit 1
fi

# download exfor database
mkdir ${EXFOR_MASTER_DIR} &&
cd ${EXFOR_MASTER_DIR} &&
declare -a exfor_tarfiles &&
exfor_tarfiles+=("entries_10001-10535.tar.xz") &&
exfor_tarfiles+=("entries_10536-11690.tar.xz") &&
exfor_tarfiles+=("entries_11691-13569.tar.xz") &&
exfor_tarfiles+=("entries_13570-13768.tar.xz") &&
exfor_tarfiles+=("entries_13769-14239.tar.xz") &&
exfor_tarfiles+=("entries_14240-20118.tar.xz") &&
exfor_tarfiles+=("entries_20119-21773.tar.xz") &&
exfor_tarfiles+=("entries_21774-22412.tar.xz") &&
exfor_tarfiles+=("entries_22413-22921.tar.xz") &&
exfor_tarfiles+=("entries_22922-23129.tar.xz") &&
exfor_tarfiles+=("entries_23130-23250.tar.xz") &&
exfor_tarfiles+=("entries_23251-23324.tar.xz") &&
exfor_tarfiles+=("entries_23325-23415.tar.xz") &&
exfor_tarfiles+=("entries_23416-A0099.tar.xz") &&
exfor_tarfiles+=("entries_A0100-C1030.tar.xz") &&
exfor_tarfiles+=("entries_C1031-D0487.tar.xz") &&
exfor_tarfiles+=("entries_D0488-E1841.tar.xz") &&
exfor_tarfiles+=("entries_E1842-F1045.tar.xz") &&
exfor_tarfiles+=("entries_F1046-O0678.tar.xz") &&
exfor_tarfiles+=("entries_O0679-V1002.tar.xz") &&
for exfor_tarfile in "${exfor_tarfiles[@]}"; do
    cur_exfor_url="http://www.nucleardata.com/storage/repos/exfor/${exfor_tarfile}"
    echo downloading ${cur_exfor_url}
    wget "${cur_exfor_url}"
    tar -xvf ${exfor_tarfile}
    rm ${exfor_tarfile}
done &&
python3 /usr/local/bin/populate_exfor_couchdb.py \
    --path "$(pwd)" --ext .txt \
    --couchdb_url http://${COUCHDB_USER}:${COUCHDB_PASSWORD}@localhost:5984 \
    --dbname ${DBNAME}

if [ "$?" -ne 0 ]; then
    echo "ERROR: Something went wrong during the ingestion of EXFOR content"
    echo "       into the CouchDB database. Aborting."
fi

rm -rf /install_tmpdir
