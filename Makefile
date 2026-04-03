BIN_DIR = $(HOME)/.local/bin
CONFIG_DIR = $(HOME)/.config/ctt
SRC_DIR = src

# Allow: make run new, make run ls, etc.
ifeq (run,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif

build:
	cd $(SRC_DIR) && moon build --target native --release

run: build
	$(SRC_DIR)/_build/native/release/build/cmd/main/main.exe $(RUN_ARGS)

install: build
	mkdir -p $(BIN_DIR) $(CONFIG_DIR)
	cp $(SRC_DIR)/_build/native/release/build/cmd/main/main.exe $(BIN_DIR)/ctt
	cp .worktree-link-ignore $(CONFIG_DIR)/.worktree-link-ignore

uninstall:
	rm -f $(BIN_DIR)/ctt
	rm -f $(CONFIG_DIR)/.worktree-link-ignore
	rmdir $(CONFIG_DIR) 2>/dev/null || true

clean:
	cd $(SRC_DIR) && moon clean

.PHONY: build run install uninstall clean
