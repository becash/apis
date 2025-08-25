#!/bin/bash

PWD=$(pwd)
TS=$(/bin/date "+%s")
DESTDIR_GO=./gen_go
DESTDIR_GRAPHQL=./gen_graphql

rm -rf ${DESTDIR_GO} ./*/README.md
mkdir -p ${DESTDIR_GO}

# Build environment
echo ---------------------BUILD ENVIRONMENT CONTAINER--------------------------
docker build -f code_generator/DockerfileGo --tag=protoc-go ./
docker run -v ${PWD}:/root/data protoc-go go mod init github.com/becash/apis


# Generate go files
echo ---------------------GENERATE GO FILES------------------------------------
docker run -v ${PWD}:/root/data protoc-go \
    protoc \
		--proto_path=proto \
		--experimental_allow_proto3_optional \
		--go_out=${DESTDIR_GO} \
		--go_opt=module=github.com/becash/apis/gen_go \
		--go-grpc_out=${DESTDIR_GO} \
		--go-grpc_opt=paths=source_relative \
		--grpc-gateway_out ${DESTDIR_GO} \
    --grpc-gateway_opt paths=source_relative \
		./proto/*/*.proto


echo ---------------------GENERATE GRAPHQL FILES --------------------------------
docker run -v ${PWD}:/root/data protoc-go \
    protoc \
		--proto_path=proto \
		--experimental_allow_proto3_optional \
		--gql_out=merge=false,prefix=true,go_model=github.com/becash/apis/gen_go/,output=:${DESTDIR_GRAPHQL} \
		./proto/*/*.proto
@python patch_graphql.py


# Set permissions
echo ---------------------SET PERMISSIONS--------------------------------------
docker run -v ${PWD}:/root/data protoc-go chmod -R 777 ${DESTDIR_GRAPHQL}
docker run -v ${PWD}:/root/data protoc-go chmod -R 777 ${DESTDIR_GO}


# Generate documentation, from protofiles
echo ---------------------GENERATE DOCUMENTATION-------------------------------
for dir in ./gen_go/*/; do
  PROJECT="${dir%/}"           # remove trailing slash
  PROJECT="${PROJECT##*/}"     # keep only the last path component

#  generate documentation, from protofiles
  docker run -v "${PWD}":/root/data protoc-go \
    protoc \
    --proto_path=./proto --doc_out=./proto/"${PROJECT}"/ --doc_opt=markdown,DOCUMENTATION.md ./proto/"${PROJECT}"/*.proto

  cat ./proto/"${PROJECT}"/ABOUT.md ./proto/"${PROJECT}"/DOCUMENTATION.md >./proto/"${PROJECT}"/README.md

  unlink ./proto/"${PROJECT}"/DOCUMENTATION.md
done

#
#echo ---------------------GENERATE UML-----------------------------------------
#docker run -v "${PWD}":/root/data protoc-go ./code_generator/uml/protodot -src ./proto/structure_999/structure.proto -output Category -select Category
#docker run -v "${PWD}":/root/data protoc-go chmod -R 777 ./gen_uml
#rm -f ./gen_uml/Category.dot
#mv -f ./gen_uml/Category.dot.png ./gen_uml/Category.png
#echo -e "## Actual Category schema\n\n![Actual Category schema](../../gen_uml/Category.png)\n\n$(cat ./proto/structure_999/README.md)" > ./proto/structure_999/README.md
#
