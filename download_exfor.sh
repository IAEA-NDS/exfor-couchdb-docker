#!/usr/bin/env bash
curl --output exfor_urls.txt http://www.nucleardata.com/storage/repos/exfor/exfor_urls.txt
head -n 2 exfor_urls.txt > exfor_urls2.txt
xargs -n 1 curl -O < exfor_urls2.txt
ls *.tar.xz | xargs -n 1 tar -xf
