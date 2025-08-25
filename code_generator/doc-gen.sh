#!/bin/bash

PWD=$(pwd)

# Generate documentation, from protofiles
echo ---------------------GENERATE DOCUMENTATION-------------------------------
DIRS=$(find gen_py2/apis/* -type d -print)
for DIRECTORY in $DIRS; do
  PROJECT=$(echo $DIRECTORY | cut -d'/' -f 3)

  #generate documentation, from protofiles
  docker run -v "${PWD}":/root/data protoc-go \
    protoc \
    --proto_path=./proto --doc_out=./proto/"${PROJECT}"/ --doc_opt=markdown,DOCUMENTATION.md ./proto/"${PROJECT}"/*.proto

  cat ./proto/"${PROJECT}"/ABOUT.md ./proto/"${PROJECT}"/DOCUMENTATION.md >./proto/"${PROJECT}"/README.md

  unlink ./proto/"${PROJECT}"/DOCUMENTATION.md
done
