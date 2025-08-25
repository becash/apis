#!/usr/bin/env bash
# roots
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROTO_DIR="${REPO_ROOT}"
OUT_DIR="${REPO_ROOT}/gen"

mkdir -p "${OUT_DIR}"

# Ensure required protoc plugins are available
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing $1. Install it and re-run."; exit 1; }; }

need protoc
# Go plugins (if you already generate Go/grpc code elsewhere, these will already exist)
# need protoc-gen-go
# need protoc-gen-go-grpc

# gRPC-Gateway / OpenAPI plugins
need protoc-gen-grpc-gateway
need protoc-gen-openapiv2

# GraphQL plugin (already used in your project; keep as-is if you have it)
# need protoc-gen-graphql

# Common include paths for protoc
INCLUDES=(
  "-I" "${PROTO_DIR}"
  "-I" "${GOOGLEAPIS_DIR}"
  "-I" "${GW_OPTIONS_DIR}"
)

# Input protos
PROTOS=(
  "demo/api.proto"
)

# 1) Generate gRPC-Gateway reverse proxy stubs
protoc "${INCLUDES[@]}" \
  --grpc-gateway_out "${OUT_DIR}" \
  --grpc-gateway_opt=paths=source_relative,generate_unbound_methods=true \
  "${PROTOS[@]}"

# ... existing code ...

# 2) Generate OpenAPI v2 (Swagger) specification
#    - allow_merge merges multiple files into one swagger.json if you add more protos later.
#    - merge_file_name sets the base name of the merged file.
mkdir -p "${OUT_DIR}/openapi"
protoc "${INCLUDES[@]}" \
  --openapiv2_out "${OUT_DIR}/openapi" \
  --openapiv2_opt=allow_merge=true,merge_file_name=demo \
  "${PROTOS[@]}"

# ... existing code ...

# 3) (Optional) If you also want to keep your existing GraphQL and Go outputs in this script, keep those invocations here.
# Example placeholders (uncomment and adjust paths/options to your setup):
# protoc "${INCLUDES[@]}" --go_out="${OUT_DIR}" --go_opt=paths=source_relative --go-grpc_out="${OUT_DIR}" --go-grpc_opt=paths=source_relative "${PROTOS[@]}"
# protoc "${INCLUDES[@]}" --graphql_out="${OUT_DIR}/graphql" --graphql_opt=merge=true,schema=demo.graphql "${PROTOS[@]}"

echo "gRPC-Gateway stubs -> ${OUT_DIR}"
echo "OpenAPI (Swagger)  -> ${OUT_DIR}/openapi/demo.swagger.json"