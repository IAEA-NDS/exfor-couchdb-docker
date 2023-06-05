### EXFOR-CouchDB - version 0.6.0

This repository contains a Dockerfile that extends the
[CouchDB Docker Image][couchdb-docker] with scripts to populate a
CouchDB database with the data from the [EXFOR library][exfor-library].
[CouchDB][couchdb-website] is a NoSQL document-oriented database with
documents being JSON objects.
The EXFOR to JSON format conversion is achieved by the [exfor-parserpy] package.

As this repository is still under development, the structure of the JSON
documents may change in the future. The script to ingest EXFOR content
into the database retrieves the EXFOR master files from [this repository][exfor-master].
If you are looking for a graphical interface to the EXFOR library, you can
use the [EXFOR web retrieval system][exfor-web].

If you have used this repository in a previous state, please note that
due to a switch from the R [exforParser] package to the
Python [exfor-parserpy] package, the structure of the
JSON documents differs in some aspects. Most noteworthy,
the field name `TABLE` of the `DATA` section got renamed to `DATA` and the
information of the first subentries was not merged into subsequent ones.

[couchdb-docker]: https://hub.docker.com/_/couchdb/
[exfor-parserpy]: https://github.com/iaea-nds/exfor-parserpy
[exfor-library]: https://www.sciencedirect.com/science/article/abs/pii/S0090375214005171
[exfor-master]: https://github.com/iaea-nds/exfor_master
[exfor-web]: https://www-nds.iaea.org/exfor/
[couchdb-website]: https://couchdb.apache.org/
[docker-install]: https://docs.docker.com/install/
[exforParser]: https://github.com/gschnabel/exforParser


## Installation instructions

To install the extended CouchDB Docker image, perform the following steps:

1. If not already done, install the Docker application.
   The Community edition is free of charge.
   Installation instructions for Windows, Mac and Linux can be found [here][docker-install].
2. [Download](https://github.com/iaea-nds/exfor-couchdb-docker/archive/master.zip)
   and unzip the content of this GitHub repository to a local folder.
3. Open a terminal and change into this directory.
   Execute the command: `docker build -t exfor-couchdb .`
   You may need elevated privileges, e.g. `sudo`, to run this and
   all following commands involving the `docker` instruction.

Now you can start up a container running the CouchDB server by executing
```
docker run -d \
--name exfor-couchdb-container \
-p 5984:5984 --rm \
--mount source=exfor-data,target=/opt/couchdb/data \
-e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password exfor-couchdb
```
This instruction will also create a Docker volume named `exfor-data`
to ensure that the data written in the next step will persist
even after stopping and removing the container.
The CouchDB server will be available on port `5984` on the host.

Finally, to create a database with the EXFOR library on the CouchDB server, run
```
docker exec exfor-couchdb-container /usr/local/bin/populate.sh
```
This instruction will take tens of minutes to complete as it will
download the EXFOR master files available [here][exfor-master],
convert them using the [exfor-parserpy] package to the JSON format and
store them in the database. By default, the name of the database will
be `exfor`. You may append additional arguments to the
`docker exec` command, which are documented in the header of the
`populate.sh` script.

Once the `docker exec` command has finished, you may stop and remove the
Docker container by
```
docker stop exfor-couchdb-container
```

From now on, if you want to use the EXFOR CouchDB database,
execute the `docker run` instruction above. Importantly,
for accessing the database, such as exemplified in the next
section, the container needs to be up and running, which can
be checked by `docker ps`.


## Usage in Python

There are several possibilities to access the EXFOR CouchDB database
from Python. In principle, the `requests` module can do the job.
For more convenience, you may consider using dedicated packages,
such as the `couchdb` or `cloudant` package. The following example
makes use of the `cloudant` package.

```python
from cloudant.client import CouchDB

client = CouchDB('admin', 'password', url='http://localhost:5984', connect=True)
exfor = client['exfor']
subent = exfor['10502002']

subent['BIB']['REACTION']
# columns names of the data table
subent['DATA']['DATA'].keys()
# a dictionary that stores the units
# associated with the columns
subent['DATA']['UNIT']

# retrieving the column with measured data
subent['DATA']['DATA']['DATA']
# and the associated labels, such as the angle here
subent['DATA']['DATA']['ANG']

# the information about the author is stored in the
# first subentry (first five digits denote entry id
# and last three subentry id
first_subent = exfor['10502001']
first_subent['BIB']['AUTHOR']

# find subentries based on specific criteria
# e.g., REACTION cross section should match a specific regular expression
#       and EN and DATA column should exist
selector = {
        'BIB.REACTION': {
            '$regex': r'\(26-FE-56\(N,[^)]+\)[^,]*,,SIG\)'
        },
        'DATA.DATA.DATA': {'$exists': True},
        'DATA.DATA.EN': {'$exists': True}
    }

docs = exfor.get_query_result(selector)

# retrieve information of specific EXFOR subentry
specific_doc = docs[0][0]
specific_doc['BIB']['REACTION']

# cycle through results
for curdoc in docs:
    print(curdoc['BIB']['REACTION'])
```

## Usage from command line

For the following examples, we assume that the command line tools `jq` and `curl` are available.

```shell
# retrieve EXFOR subentry 11464003
curl -X GET http://admin:password@localhost:5984/exfor/11464003 > result.json

# extract specific fields
jq -r '.DATA.DATA.EN[]' result.json
jq -r '.DATA.DATA.DATA[]' result.json
jq -r '.DATA.UNIT' result.json

# to obtain the associated author, we need to access the
# first subentry (the first five digits are the entry id and
# the last three the subentry id.
curl -X GET http://admin:password@localhost:5984/exfor/11464001 > result.json
jq -r '.BIB.AUTHOR' result.json

# find EXFOR subentries with participation of FERGUSON
curl -s -X POST --header "Content-Type: application/json" \
     -d '{"selector": {"BIB": {"AUTHOR": { "$regex": "FERGUSON"}}}, "limit": 4 }' \
     http://admin:password@localhost:5984/exfor/_find > result.json

# extract only particular fields, e.g., AUTHOR, DETECTOR and FACILITY column:
curl -s -X POST --header "Content-Type: application/json" -d '{
       "selector": {"BIB": {"AUTHOR": { "$regex": "FERGUSON"}}},
       "limit": 4,
       "fields": ["BIB.AUTHOR", "BIB.DETECTOR", "BIB.FACILITY"]
     }' \
     http://admin:password@localhost:5984/exfor/_find | jq .
```

## Usage in R

Access to the CouchDB database is possible with the `sofa` package.
```R
library(sofa)

# connect to database
z <- Cushion$new(
    host = "localhost",
    transport = 'http',
    port = 5984,
    user = 'admin',
    pwd = 'password'
)

# retrieve document with specific EXFOR ID
docs <- db_query(z, dbname = "exfor", selector = list(`_id` = '10022010'))$docs

# retrieve specific fields
docs[[1]][['BIB']][['REACTION']]
# or docs[[1]]$BIB$REACTION
docs[[1]][['DATA']][['DATA']]

# search documents matching specific criteria
docs <- db_query(z, dbname = "exfor", selector = list(
    'DATA.DATA.EN' = list('$exists' = TRUE),
    'DATA.DATA.DATA' = list('$exists' = TRUE)), limit=30)$docs

# cycle through results
for (curdoc in docs) {
    print(curdoc[['BIB']][['REACTION']])
}
```


## Legal note

The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.
