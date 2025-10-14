MKDIR := 'mkdir -p'
RM := 'rm -rf ' + TMP_DIR
DOWN := 'curl -fsSL'
DOWN_OUT := '-o'

clean:
    {{RM}}

fetch-proto:
    {{MKDIR}} "{{TMP_DIR}}"
    {{DOWN}} "https://raw.githubusercontent.com/esclient/protos/{{PROTO_TAG}}/{{PROTO_NAME}}" {{DOWN_OUT}} "{{TMP_DIR}}/{{PROTO_NAME}}"

run:
    ENV=dev ./tools/load_envs.sh go run ./cmd

gen-stubs: fetch-proto
    {{MKDIR}} "{{OUT_DIR}}"
    protoc \
      --proto_path="{{TMP_DIR}}" \
      --go_out="{{OUT_DIR}}" \
      {{GO_MODULE_GO_OPT}} \
      --go-grpc_out="{{OUT_DIR}}" \
      {{GO_MODULE_GRPC_OPT}} \
      "{{TMP_DIR}}/{{PROTO_NAME}}"

update: gen-stubs clean

format:
    # placeholder

lint:
    # placeholder

test:
    # placeholder

prepare: format lint test
