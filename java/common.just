MKDIR := 'mkdir -p'
RM := 'rm -rf ' + TMP_DIR
DOWN := 'curl -fsSL'
DOWN_OUT := '-o'

clean:
    {{RM}}

fetch-proto:
    {{MKDIR}} "{{TMP_DIR}}"
    {{DOWN}} "https://raw.githubusercontent.com/esclient/protos/{{PROTO_TAG}}/{{PROTO_NAME}}" {{DOWN_OUT}} "{{TMP_DIR}}/{{PROTO_NAME}}"

build:
    mvn -DskipTests package

run: build
    ENV=dev ./tools/load_envs.sh java -jar target/rating-service.jar

gen-stubs: fetch-proto
    {{MKDIR}} "{{OUT_DIR}}"
    protoc \
      --proto_path="{{TMP_DIR}}" \
      --java_out="{{OUT_DIR}}" \
      --grpc-java_out="{{OUT_DIR}}" \
      "{{TMP_DIR}}/{{PROTO_NAME}}"

update: gen-stubs clean

format:
    mvn fmt:format

lint:
    mvn -DskipTests verify

test:
    mvn test

prepare: format lint test
