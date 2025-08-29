#!/bin/bash

PWD=$(pwd)
TS=$(/bin/date "+%s")
DESTDIR_GO=./gen_go
DESTDIR_OPENAPI=./gen_openapi

rm -rf ${DESTDIR_GO}  ${DESTDIR_OPENAPI}
mkdir -p ${DESTDIR_GO} ${DESTDIR_OPENAPI}
#
## Build environment
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

echo "---------------------GENERATE OPENAPI FILES--------------------------------"
for dir in ./gen_go/*/; do
  PROJECT="${dir%/}"           # remove trailing slash
  PROJECT="${PROJECT##*/}"     # keep only the last path component
  [ "$PROJECT" = "common" ] && continue
  mkdir ${DESTDIR_OPENAPI}/${PROJECT}
  docker run -v ${PWD}:/root/data protoc-go \
      protoc \
      --proto_path=proto \
      --openapi_out=fq_schema_naming=true,default_response=false:${DESTDIR_OPENAPI}/${PROJECT} \
      ./proto/*/*.proto

  docker run -v ${PWD}:/root/data protoc-go \
    oapi-codegen -config ./proto/${PROJECT}/cfg.yaml ${DESTDIR_OPENAPI}/${PROJECT}/openapi.yaml
done;

##TODO Generate documentation, from protofiles
#echo ---------------------GENERATE DOCUMENTATION-------------------------------
#for dir in ./gen_go/*/; do
#  PROJECT="${dir%/}"           # remove trailing slash
#  PROJECT="${PROJECT##*/}"     # keep only the last path component
#
#  docker run -v "${PWD}":/root/data protoc-go \
#    protoc \
#    --proto_path=./proto --doc_out=./proto/"${PROJECT}"/ --doc_opt=markdown,DOCUMENTATION.md ./proto/"${PROJECT}"/*.proto
#
#  cat ./proto/"${PROJECT}"/ABOUT.md ./proto/"${PROJECT}"/DOCUMENTATION.md >./proto/"${PROJECT}"/README.md
#
#  unlink ./proto/"${PROJECT}"/DOCUMENTATION.md
#done
#
## Set permissions
echo ---------------------SET PERMISSIONS--------------------------------------
docker run -v ${PWD}:/root/data protoc-go chmod -R 777 ${DESTDIR_GO}
docker run -v ${PWD}:/root/data protoc-go chmod -R 777 ${DESTDIR_OPENAPI}
