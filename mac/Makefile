export SHELL                   := /bin/zsh
export SETUP_DIR               := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

# ログ関連の変数
export LOG_DIR                 := $(SETUP_DIR)/logs
export LOG_TIMESTAMP           := $(shell date +%Y%m%d_%H%M%S)
export INSTALL_LOG_FILE        := $(LOG_DIR)/install_$(LOG_TIMESTAMP).log
export UPDATE_LOG_FILE         := $(LOG_DIR)/update_$(LOG_TIMESTAMP).log
export ERROR_LOG_FILE          := $(LOG_DIR)/errors_$(LOG_TIMESTAMP).log

# brew-packages.jsonのパス
export PACKAGES_JSON           := $(SETUP_DIR)/brew-packages.json

# インタラクティブモード用の一時ファイルのパス
export SELECTED_PACKAGES_FILE := $(SETUP_DIR)/logs/brew-selected-packages.txt

# 実行オプション（デフォルト値）
export DRY_RUN                 := false
export SKIP_UPDATE             := false
export CATEGORY                :=
export INTERACTIVE             := false

# 擬似ターゲット（タスクターゲット）の宣言
.PHONY: all \
	help \
	install \
	install-interactive \
	dry-run \
	install-formula \
	install-cask \
	test \
	update \
	show-install-logs \
	show-update-logs \
	show-error-logs \
	clean-logs

all: help

help: ##ヘルプ表示
	@echo ""
	@echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
	@echo "\033[1;33m🚀 macOS Development Environment Setup\033[0m"
	@echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
	@echo ""
	@echo "\033[1;32m📦 インストール:\033[0m"
	@echo "  \033[36mmake install\033[0m              開発ツールのインストール"
	@echo "  \033[36mmake install-interactive\033[0m  インタラクティブ選択インストール"
	@echo "  \033[36mmake dry-run\033[0m              インストール内容の確認"
	@echo "  \033[36mmake install-formula\033[0m      Homebrew Formulaのみ"
	@echo "  \033[36mmake install-cask\033[0m         Homebrew Caskのみ"
	@echo ""
	@echo "\033[1;32m🧪 テストと確認:\033[0m"
	@echo "  \033[36mmake test\033[0m                 実行可否をチェック"
	@echo ""
	@echo "\033[1;32m🔧 メンテナンス:\033[0m"
	@echo "  \033[36mmake update\033[0m               ツールの更新"
	@echo "  \033[36mmake clean-logs\033[0m           ログファイル削除"
	@echo ""
	@echo "\033[1;32m📊 ログ:\033[0m"
	@echo "  \033[36mmake show-install-logs\033[0m    最新のインストールログを表示"
	@echo "  \033[36mmake show-update-logs\033[0m     最新のアップデートログを表示"
	@echo "  \033[36mmake show-error-logs\033[0m      エラーログの内容を表示"
	@echo ""
	@echo "\033[1;32m❓ ヘルプ:\033[0m"
	@echo "  \033[36mmake help\033[0m                 このヘルプを表示"
	@echo ""
	@echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
	@echo ""

install: ##開発ツールのインストール
	@$(SHELL) $(SETUP_DIR)/bin/install.zsh

install-interactive: ##インタラクティブ選択インストール（fzfで選択）
	@INTERACTIVE=true $(SHELL) $(SETUP_DIR)/bin/install.zsh

dry-run: ##インストール内容の確認（実際にはインストールしない）
	@DRY_RUN=true $(SHELL) $(SETUP_DIR)/bin/install.zsh

install-formula: ##Homebrew Formulaのみインストール
	@CATEGORY=formula $(SHELL) $(SETUP_DIR)/bin/install.zsh

install-cask: ##Homebrew Caskのみインストール
	@CATEGORY=cask $(SHELL) $(SETUP_DIR)/bin/install.zsh

update: ##開発ツールの更新
	@$(SHELL) $(SETUP_DIR)/bin/update.zsh

test: ##コマンドの実行可否をチェック
	@${SHELL} $(SETUP_DIR)/bin/test.zsh

show-install-logs: ##最新のインストールログの内容を表示
	@LATEST_LOG=$$(ls -t $(LOG_DIR)/install_*.log 2>/dev/null | head -1); \
	if [ -z "$$LATEST_LOG" ]; then \
		echo ""; \
		echo "\033[1;33m⚠️  インストールログファイルが見つかりません\033[0m"; \
		echo ""; \
		echo "  まだインストールを実行していないようです。"; \
		echo "  以下のコマンドを実行してください:"; \
		echo ""; \
		echo "    \033[36mmake install\033[0m"; \
		echo ""; \
	else \
		echo ""; \
		echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"; \
		echo "\033[1;32m📄 最新のインストールログファイル\033[0m"; \
		echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"; \
		echo "  $$LATEST_LOG"; \
		echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"; \
		echo ""; \
		cat "$$LATEST_LOG"; \
		echo ""; \
	fi

show-update-logs: ##最新のアップデートログの内容を表示
	@LATEST_LOG=$$(ls -t $(LOG_DIR)/update_*.log 2>/dev/null | head -1); \
	if [ -z "$$LATEST_LOG" ]; then \
		echo ""; \
		echo "\033[1;33m⚠️  アップデートログファイルが見つかりません\033[0m"; \
		echo ""; \
		echo "  まだアップデートを実行していないようです。"; \
		echo "  以下のコマンドを実行してください:"; \
		echo ""; \
		echo "    \033[36mmake update\033[0m"; \
		echo ""; \
	else \
		echo ""; \
		echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"; \
		echo "\033[1;32m📄 最新のアップデートログファイル\033[0m"; \
		echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"; \
		echo "  $$LATEST_LOG"; \
		echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"; \
		echo ""; \
		cat "$$LATEST_LOG"; \
		echo ""; \
	fi

show-error-logs: ##エラーログの内容を表示
	@LATEST_ERROR=$$(ls -t $(LOG_DIR)/errors_*.log 2>/dev/null | head -1); \
	if [ -z "$$LATEST_ERROR" ]; then \
		echo ""; \
		echo "\033[1;32m✅ エラーログが見つかりません\033[0m"; \
		echo ""; \
		echo "  エラーは記録されていません。"; \
		echo ""; \
	else \
		echo ""; \
		echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"; \
		echo "\033[1;31m⚠️  最新のエラーログファイル\033[0m"; \
		echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"; \
		echo "  $$LATEST_ERROR"; \
		echo "\033[1;34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"; \
		echo ""; \
		cat "$$LATEST_ERROR"; \
		echo ""; \
	fi

clean-logs: ##古いログファイルを削除
	@echo "Cleaning up old log files..."
	@rm -f $(SETUP_DIR)/logs/*.log
	@echo "Log files cleaned"
