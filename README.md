### EXFOR-CouchDB

This repository contains a Dockerfile and accompanying scripts to
setup a Docker container with a CouchDB database that is filled
with the EXFOR database.

Note: The EXFOR entries are taken from [www.nucleardata.com][http://www.nucleardata.com]
which lag behind the most up-to-date version of the EXFOR library.
The most recent can be requested from the 
[Nuclear Data Section of the IAEA](mailto:nds.contact-point@iaea.org).

## Installation instructions

1. If not already done, install the Docker application.
   The Community edition is free of charge.
   Installation instructions for Windows, Mac and Linux can be found [here](https://docs.docker.com/install/).
2. [Download](https://github.com/gschnabel/exfor-couchdb-docker/archive/master.zip) the content of this GitHub repository to a local folder.
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
client = CouchDB(‘admin’, ‘password’, url=’http://localhost:5984’, connect=True)

# object to specifically represent the EXFOR database
# (in principle CouchDB can manage several databases in parallel)
exfor = client[‘exfor’]

# request subentry using its EXFOR ID
subent = exfor[‘10502002’]

# subnet is a normal python dictionary
# some examples of available items, which mirror the structure
# of a EXFOR subentry

subent[‘BIB’][‘REACTION’]
subent[‘BIB’][‘AUTHOR’]
subent[‘DATA’][‘DESCR’]
subent[‘DATA’][‘UNIT’]

# table is also a dictionary where names of the keys reflect column names
subent[‘DATA’][‘TABLE’]

# access the DATA column
subent[‘DATA’][‘TABLE’][‘DATA’]

# access the ANG column, etc.
subent[‘DATA’][‘TABLE’][‘ANG’]
```
