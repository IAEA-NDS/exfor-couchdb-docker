#!/usr/bin/env bash
curl -L --output exforParser.zip http://nugget.link/cc60e34b7833b942c8c5e67a2488dfd090ffec4dd2142d350f8fbb4771599d20/zip
unzip exforParser.zip

exforParserDir="exforParser-c45d6c61766faa1fdf6130a065242e15700d39e2"
R CMD INSTALL $exforParserDir
rm exforParser.zip
rm -rf $exforParserDir
