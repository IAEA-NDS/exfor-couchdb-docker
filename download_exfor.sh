#!/usr/bin/env bash
curl --output exfor_urls.txt http://www.nucleardata.com/storage/repos/exfor/exfor_urls.txt
xargs -n 1 curl -O < exfor_urls.txt
ls *.tar.xz | xargs -n 1 tar -xf
