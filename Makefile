BIN_DIR = $(HOME)/.local/bin
CONFIG_DIR = $(HOME)/.config/ctt
SRC_DIR = src

build:
	cd $(SRC_DIR) && moon build --target native --release

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

.PHONY: build install uninstall clean
