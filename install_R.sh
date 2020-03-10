#!/usr/bin/env bash

apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF'
echo 'deb https://cloud.r-project.org/bin/linux/debian buster-cran35/' >> /etc/apt/sources.list
echo 'deb-src https://cloud.r-project.org/bin/linux/debian buster-cran35/' >> /etc/apt/sources.list
apt update
apt install -y r-base
apt install -y libcurl4-openssl-dev
Rscript -e 'install.packages("Rcpp", repos="https://cran.rstudio.com")'
Rscript -e 'install.packages("data.table", repos="https://cran.rstudio.com")'
Rscript -e 'install.packages("sofa", repos="https://cran.rstudio.com")'
