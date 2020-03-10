#!/usr/bin/env bash

mkdir /exfor
cd /exfor
/usr/local/bin/init_basedb.sh
/usr/local/bin/download_exfor.sh
Rscript --vanilla --no-save --no-restore /usr/local/bin/fill_couchdb.R
