.PHONY: clean fetch-proto gen-stubs update format lint test

ifeq ($(OS),Windows_NT)
MKDIR    = powershell -Command "New-Item -ItemType Directory -Force -Path"
RM       = powershell -NoProfile -Command "Remove-Item -Path '$(TMP_DIR)' -Recurse -Force"
DOWN     = powershell -Command "Invoke-WebRequest -Uri"
DOWN_OUT = -OutFile
else
MKDIR    = mkdir -p
RM       = rm -rf $(TMP_DIR)
DOWN     = wget
DOWN_OUT = -O
endif

docker-build:
	docker build --pull --no-cache --build-arg PORT=$(PORT) -t $(SERVICE_NAME) .

run: docker-build
	docker run --rm -it \
		--env-file .env \
		-p $(PORT):$(PORT) \
		$(SERVICE_NAME)

clean:
	$(RM)

fetch-proto:
	$(MKDIR) "$(TMP_DIR)"
	$(DOWN) "https://raw.githubusercontent.com/esclient/protos/$(PROTO_TAG)/$(PROTO_NAME)" $(DOWN_OUT) "$(TMP_DIR)/$(PROTO_NAME)"

gen-stubs: fetch-proto
	$(MKDIR) "$(OUT_DIR)"
	protoc \
		--proto_path="$(TMP_DIR)" \
		--java_out="$(OUT_DIR)" \
		--grpc-java_out="$(OUT_DIR)" \
		"$(TMP_DIR)/$(PROTO_NAME)"

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

dev-check: format lint test
	@echo "All checks passed! ✅"