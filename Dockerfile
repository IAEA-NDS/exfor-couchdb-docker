FROM couchdb:3


# install R
COPY ./install_R.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install_R.sh \
    && /usr/local/bin/install_R.sh

# install EXFOR JSON Parser
COPY ./install_exforParser.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install_exforParser.sh \
    && /usr/local/bin/install_exforParser.sh

# initialize couchdb
COPY ./prod.ini /opt/couchdb/etc/local.d/

# install scripts for filling the database 
COPY ./init_basedb.sh /usr/local/bin/
COPY ./download_exfor.sh /usr/local/bin/
COPY ./fill_couchdb.R /usr/local/bin/
COPY ./setup_exfor_couchdb.sh /usr/local/bin
RUN chmod +x /usr/local/bin/init_basedb.sh
RUN chmod +x /usr/local/bin/download_exfor.sh
RUN chmod +x /usr/local/bin/setup_exfor_couchdb.sh

EXPOSE 5984
CMD  /opt/couchdb/bin/couchdb
