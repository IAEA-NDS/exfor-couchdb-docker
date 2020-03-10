#!/usr/bin/env bash
curl --output exforParser.zip https://codeload.github.com/gschnabel/exforParser/zip/5028766800464592ced6fc216712e08d0556b170
unzip exforParser.zip

exforParserDir="exforParser-5028766800464592ced6fc216712e08d0556b170"
R CMD INSTALL $exforParserDir
rm exforParser.zip
rm -rf $exforParserDir
