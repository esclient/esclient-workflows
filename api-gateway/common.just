MKDIR := 'mkdir -p'
RM := 'rm -rf ' + TMP_DIR
DOWN := 'curl -fsSL'
DOWN_OUT := '-o'

clean:
    {{RM}}

fetch-proto tag name:
    {{MKDIR}} "{{TMP_DIR}}"
    {{DOWN}} "{{PROTO_REPO}}/{{tag}}/{{name}}" {{DOWN_OUT}} "{{TMP_DIR}}/{{name}}"

run:
    ENV=dev PYTHONPATH=src ./tools/load_envs.sh pdm run python -u -m apigateway.server

gen-stubs name out_dir:
    {{MKDIR}} "{{out_dir}}"
    pdm run python -m grpc_tools.protoc \
      --proto_path="{{TMP_DIR}}" \
      --python_out="{{out_dir}}" \
      --grpc_python_out="{{out_dir}}" \
      --pyi_out="{{out_dir}}" \
      "{{TMP_DIR}}/{{name}}"
    for f in "{{out_dir}}"/*_pb2_grpc.py; do [ -f "$f" ] && sed -i 's/^import \(.*_pb2\)/from . import \1/' "$f"; done


update name:
    case "{{name}}" in \
      comment) tag="{{COMMENT_PROTO_TAG}}"; proto="{{COMMENT_PROTO_NAME}}"; out="{{OUT_DIR}}/comment";; \
      user)    tag="{{USER_PROTO_TAG}}";    proto="{{USER_PROTO_NAME}}";    out="{{OUT_DIR}}/user";; \
      rating)  tag="{{RATING_PROTO_TAG}}";  proto="{{RATING_PROTO_NAME}}";  out="{{OUT_DIR}}/rating";; \
      mod)     tag="{{MOD_PROTO_TAG}}";     proto="{{MOD_PROTO_NAME}}";     out="{{OUT_DIR}}/mod";; \
      *) echo "Unknown proto: {{name}} (expected: comment | user | rating | mod)" >&2; exit 1;; \
    esac; \
    just fetch-proto "$tag" "$proto"; \
    just gen-stubs "$proto" "$out"; \
    just clean

format:
    black .
    isort .
    ruff check . --fix

lint:
    black --check .
    isort . --check --diff
    flake8 .
    ruff check .
    mypy --strict .

test:
    pytest \
      --cov=src/apigateway \
      --cov-report=xml:coverage.xml

prepare: format lint test
