### EXFOR-CouchDB - version 0.2.0

This repository contains a Dockerfile and accompanying scripts to
setup a Docker container with a CouchDB database that is filled
with the EXFOR database.

**Important remarks**:

- The EXFOR entries are taken from [www.nucleardata.com](http://www.nucleardata.com) which lag behind the most up-to-date version of the EXFOR library. The most recent version can be requested from the [Nuclear Data Section of the IAEA](mailto:nds.contact-point@iaea.org).
- This repository is under development and comes without any guarantee of correctness, see *Legal Note* below for details.
- If you have ideas for improvement or want to contribute, get in touch with us.

## Installation instructions

1. If not already done, install the Docker application.
   The Community edition is free of charge.
   Installation instructions for Windows, Mac and Linux can be found [here](https://docs.docker.com/install/).
2. [Download](https://github.com/gschnabel/exfor-couchdb-docker/archive/master.zip) 
   and unzip the content of this GitHub repository to a local folder.
3. Open a terminal and change into this directory.
   Execute the command: `docker build -t exfor-couchdb .`

After these steps, a Docker image named `exfor-couchdb` has been created.
The following steps start a container with the CouchDB database application
and fill it with EXFOR data.

4. Launch a container:
   `docker run -d -p 5984:5984 --name exfor-couchdb-cont exfor-couchdb`
5. To initialize the CouchDB database with EXFOR, run:
   `docker exec exfor-couchdb-cont /usr/local/bin/setup_exfor_couchdb.sh`

After the completion of these steps, the API of the CouchDB database with EXFOR
can be accessed over `http://localhost:5984`. 
By default, the username `admin` and password `password` have to be used to
effect modifications of the EXFOR database.
These default credentials can be changed in the file `prod.ini` at the very end.
This must be done before creating the Docker image in step 3 above.

## Usage in Python

Check that the 'cloudant' module is installed.
If not, you can install it by executing `pip install cloudant`.
The following example shows access to EXFOR from Python when the container is running.

```python
from cloudant.client import CouchDB

# setup of the client object to handle database requests
client = CouchDB('admin', 'password', url='http://localhost:5984', connect=True)

# object to specifically represent the EXFOR database
# (in principle CouchDB can manage several databases in parallel)
exfor = client['exfor']

# request subentry using its EXFOR ID
subent = exfor['10502002']

# subent is a normal python dictionary
# here are some examples of available items in the dictionary, 
# which mirror the structure of a EXFOR subentry

subent['BIB']['REACTION']
subent['BIB']['AUTHOR']
subent['DATA']['DESCR']
subent['DATA']['UNIT']

# table is also a dictionary where names of the keys reflect column names
subent['DATA']['TABLE']

# access the DATA column
subent['DATA']['TABLE']['DATA']

# access the ANG column, etc.
subent['DATA']['TABLE']['ANG']
```

## Usage from command line

For the following examples, we assume that the command line tools `jq` and `curl` are available.

```shell
# retrieve EXFOR subentry 11464003
curl -X GET http://admin:password@localhost:5984/exfor/11464003 > result.json

# extract specific fields
jq -r '.BIB.AUTHOR' result.json
jq -r '.DATA.TABLE.EN[]' result.json
jq -r '.DATA.TABLE.DATA[]' result.json
jq -r '.DATA.DESCR[]' result.json
jq -r '.DATA.UNIT[]' result.json

# find EXFOR subentries with participation of FERGUSON
curl -s -X POST --header "Content-Type: application/json" \
     -d '{"selector": {"BIB": {"AUTHOR": { "$regex": "FERGUSON"}}}, "limit": 4 }' \
     http://admin:password@localhost:5984/exfor/_find > result.json

# extract only particular fields, e.g., AUTHOR, REACTION and DATA column:
curl -s -X POST --header "Content-Type: application/json" -d '{
       "selector": {"BIB": {"AUTHOR": { "$regex": "FERGUSON"}}}, 
       "limit": 4,
       "fields": ["BIB.AUTHOR", "BIB.REACTION", "DATA.TABLE.DATA"]
     }' \
     http://admin:password@localhost:5984/exfor/_find | jq .
```

## Legal note

The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.
