############################################################
#
# Python script to create a database on a CouchDB server
# and ingest data from EXFOR master files into this database.
#
# Usage:
#     python populate_exfor_couchdb.py <ARGUMENT LIST>
#
#     --path <PATH>
#         Path to the directory with the EXFOR master
#         files. Subdirectories are also traversed
#         recursively to find files.
#     --ext <EXTENSION>
#         Only files with the specified extension will
#         be matched and considered as EXFOR master files.
#         For instance, extension could be .x4
#     --couchdb_url <URL>
#         The url to connect to the CouchDB server.
#         It should contain a username and password as
#         well, e.g. http://admin:password@localhost:5984
#     --dbname <DBNAME>
#         The name of the database to be created on the
#         CouchDB server.
#
############################################################
import argparse
from exfor_parserpy import read_exfor
from exfor_parserpy.trafos import (
    reactify, depointerfy, uncommonfy, unitfy
)
import os
import couchdb
import requests


parser = argparse.ArgumentParser()
required_named = parser.add_argument_group('required named arguments')
required_named.add_argument(
    '--path', help='path to EXFOR master files', required=True
)
required_named.add_argument(
    '--ext', help='file extension of EXFOR master files', required=True
)
required_named.add_argument(
    '--couchdb_url', help='url to CouchDB database', required=True
)
required_named.add_argument(
    '--dbname', help='name of the database for storage', required=True
)

args = parser.parse_args()
exfor_path = args.path
file_ext = args.ext
couchdb_url = args.couchdb_url
dbname = args.dbname

filepaths = list()
for root, dirs, files in os.walk(exfor_path):
    curpaths = [os.path.join(root, fn) for fn in files if fn.endswith(file_ext)]
    filepaths.extend(curpaths)

couch = couchdb.Server(couchdb_url)
db = couch.create(dbname)

for fp in filepaths:
    print(f'Read {fp}')
    try:
        exfor_dic = read_exfor(fp)
    except Exception:
        print(f'ERROR: Could not parse {fp}')
        continue
    t_exfor_dic = reactify(depointerfy(uncommonfy(unitfy(exfor_dic))))
    for entryid, entry in t_exfor_dic.items():
        for subentid, subent in entry.items():
            subent['entryid'] = subent['__entryid']
            subent['subentid'] = subent['__subentid']
            subent['_id'] = subent['subentid']
            del subent['__entryid']
            del subent['__subentid']
            db.save(subent)

# create an index for faster access
create_index_url = couchdb_url.rstrip('/') + '/exfor/_index'
headers = {'Content-Type': 'application/json; charset=utf-8'}
data = {
    'index': {
        'fields': [
            'BIB.reaction_expr.target'
        ]
    },
    'name': 'target_index'
}
resp = requests.post(create_index_url, headers=headers, json=data)
print(resp)
