PORT           := env_var('PORT')
SERVICE_NAME   := env_var('SERVICE_NAME')
TMP_DIR        := env_var('TMP_DIR')
OUT_DIR        := env_var('OUT_DIR')
PROTO_TAG      := env_var('PROTO_TAG')
PROTO_NAME     := env_var('PROTO_NAME')

is_windows := os() == 'windows'

MKDIR := if is_windows { 'powershell -Command "New-Item -ItemType Directory -Force -Path"' } else { 'mkdir -p' }
RM := if is_windows { 'powershell -NoProfile -Command "Remove-Item -Path ' + TMP_DIR + ' -Recurse -Force"' } else { 'rm -rf ' + TMP_DIR }
DOWN := if is_windows { 'powershell -Command "Invoke-WebRequest -Uri"' } else { 'wget' }
DOWN_OUT := if is_windows { '-OutFile' } else { '-O' }

ok := 'echo All checks passed! ✅'

default:
    @just --list

clean:
    {{RM}}

fetch-proto:
    {{MKDIR}} "{{TMP_DIR}}"
    {{DOWN}} "https://raw.githubusercontent.com/esclient/protos/{{PROTO_TAG}}/{{PROTO_NAME}}" {{DOWN_OUT}} "{{TMP_DIR}}/{{PROTO_NAME}}"

docker-build:
    docker build --pull --no-cache --build-arg PORT={{PORT}} -t {{SERVICE_NAME}} .

run: docker-build
    docker run --rm -it \
      --env-file .env \
      -p {{PORT}}:{{PORT}} \
      {{SERVICE_NAME}}

gen-stubs: fetch-proto
    {{MKDIR}} "{{OUT_DIR}}"
    protoc \
      --proto_path="{{TMP_DIR}}" \
      --java_out="{{OUT_DIR}}" \
      --grpc-java_out="{{OUT_DIR}}" \
      "{{TMP_DIR}}/{{PROTO_NAME}}"

update: gen-stubs clean

format:
    mvn spotless:apply -Pquality

lint:
    mvn spotless:check -Pquality
    mvn checkstyle:check -Pquality
    mvn pmd:check -Pquality
    mvn spotbugs:check -Pquality

test:
    mvn test jacoco:report -Pquality

prepare: format lint test
    {{ok}}
