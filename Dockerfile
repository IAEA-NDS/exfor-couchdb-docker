FROM couchdb:3

RUN apt update \
    && apt install -y wget \
    && apt install -y zip \
    && apt install -y python3  \
    && apt install pip -y \
    && pip install requests==2.28.1  \
    && pip install couchdb==1.2  \
    && apt remove pip \
    && pip cache purge  \
    && apt clean  \
    && rm -rf /tmp/*  \
    && rm -rf ~/.cache

COPY ./populate_exfor_couchdb.py ./usr/local/bin/ 
COPY ./populate.sh ./usr/local/bin/
RUN  chmod +x /usr/local/bin/populate.sh 
