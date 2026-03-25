BIN_DIR = $(HOME)/.local/bin
CONFIG_DIR = $(HOME)/.config/ctt

install:
	mkdir -p $(BIN_DIR) $(CONFIG_DIR)
	cp ctt $(BIN_DIR)/ctt
	chmod +x $(BIN_DIR)/ctt
	cp .worktree-link-ignore $(CONFIG_DIR)/.worktree-link-ignore

uninstall:
	rm $(BIN_DIR)/ctt
	rm $(CONFIG_DIR)/.worktree-link-ignore
	rmdir $(CONFIG_DIR)

.PHONY: install uninstall
