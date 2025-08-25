NO_COLOR=$(shell echo "\033[0m")
OK_COLOR=$(shell echo "\033[32;01m")
WARN_COLOR=$(shell echo "\033[43;01m")
PWD=${shell pwd}
protolint=${shell which protolint}
protofix=${shell which protolint}
protolint+=lint proto
protofix+=-fix proto
DESTDIR_GRAPHQL=./gen_graphql

install:
	@go install github.com/yoheimuta/protolint/cmd/protolint@latest
	@sudo apt install python3-pip
#	@pip install pre-commit
#	@pre-commit install
	@sudo usermod -aG docker $$USER
	@echo "$(OK_COLOR)==> Restart the machine for changes to take effect, so that your docker group membership is re-evaluated.$(NO_COLOR)"


lint:
	@echo "$(OK_COLOR)==> Linting!$(NO_COLOR)"
	@$(protolint)
	@echo "$(OK_COLOR)==> Done!$(NO_COLOR)"


fix:
	@echo "$(OK_COLOR)==> Fixing and Formatting!$(NO_COLOR)"
	@$(protofix)
	@pre-commit run buf-format --all-files
	@echo "$(OK_COLOR)==> Done!$(NO_COLOR)"


generate:
	#@pre-commit run protolint
	@./generate.sh
	@echo "$(OK_COLOR)==> Finished generating!$(NO_COLOR)"

clear_docker_cache:
	@docker container prune -f
	@docker buildx prune -f
	@docker builder prune --all -f
