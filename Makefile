ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR:=$(ROOT_DIR)/build

LETSENCRYPT_SH_VERSION:=v0.2.0
LUA_RESTY_SHELL_VERSION:=0f88be3272c703686ef0d37f267f0616672c6931
SOCKPROC_VERSION:=0d7b390c0b4879e29b7f3dff578285c42af613dc

.PHONY:
	all \
	grind \
	install \
	lint \
	test \
	test_dependencies

all: \
	$(BUILD_DIR)/stamp-letsencrypt.sh-$(LETSENCRYPT_SH_VERSION) \
	$(BUILD_DIR)/stamp-lua-resty-shell-$(LUA_RESTY_SHELL_VERSION) \
	$(BUILD_DIR)/stamp-sockproc-$(SOCKPROC_VERSION)

install:
	install -d $(INST_LUADIR)/resty/auto-ssl
	install -m 644 lib/resty/auto-ssl.lua $(INST_LUADIR)/resty/auto-ssl.lua
	install -m 644 lib/resty/auto-ssl/init.lua $(INST_LUADIR)/resty/auto-ssl/init.lua
	install -m 644 lib/resty/auto-ssl/init_worker.lua $(INST_LUADIR)/resty/auto-ssl/init_worker.lua
	install -d $(INST_LUADIR)/resty/auto-ssl/jobs
	install -m 644 lib/resty/auto-ssl/jobs/renewal.lua $(INST_LUADIR)/resty/auto-ssl/jobs/renewal.lua
	install -d $(INST_LUADIR)/resty/auto-ssl/servers
	install -m 644 lib/resty/auto-ssl/servers/challenge.lua $(INST_LUADIR)/resty/auto-ssl/servers/challenge.lua
	install -m 644 lib/resty/auto-ssl/servers/hook.lua $(INST_LUADIR)/resty/auto-ssl/servers/hook.lua
	install -d $(INST_LUADIR)/resty/auto-ssl/shell
	install -m 755 lib/resty/auto-ssl/shell/letsencrypt_hooks $(INST_LUADIR)/resty/auto-ssl/shell/letsencrypt_hooks
	install -m 755 lib/resty/auto-ssl/shell/start_sockproc $(INST_LUADIR)/resty/auto-ssl/shell/start_sockproc
	install -m 644 lib/resty/auto-ssl/ssl_certificate.lua $(INST_LUADIR)/resty/auto-ssl/ssl_certificate.lua
	install -d $(INST_LUADIR)/resty/auto-ssl/ssl_providers
	install -m 644 lib/resty/auto-ssl/ssl_providers/lets_encrypt.lua $(INST_LUADIR)/resty/auto-ssl/ssl_providers/lets_encrypt.lua
	install -m 644 lib/resty/auto-ssl/storage.lua $(INST_LUADIR)/resty/auto-ssl/storage.lua
	install -d $(INST_LUADIR)/resty/auto-ssl/storage_adapters
	install -m 644 lib/resty/auto-ssl/storage_adapters/file.lua $(INST_LUADIR)/resty/auto-ssl/storage_adapters/file.lua
	install -m 644 lib/resty/auto-ssl/storage_adapters/redis.lua $(INST_LUADIR)/resty/auto-ssl/storage_adapters/redis.lua
	install -d $(INST_LUADIR)/resty/auto-ssl/utils
	install -m 644 lib/resty/auto-ssl/utils/shell_execute.lua $(INST_LUADIR)/resty/auto-ssl/utils/shell_execute.lua
	install -m 644 lib/resty/auto-ssl/utils/start_sockproc.lua $(INST_LUADIR)/resty/auto-ssl/utils/start_sockproc.lua
	install -m 644 lib/resty/auto-ssl/utils/run_command.lua $(INST_LUADIR)/resty/auto-ssl/utils/run_command.lua
	install -d $(INST_LUADIR)/resty/auto-ssl/vendor
	install -m 755 lib/resty/auto-ssl/vendor/letsencrypt.sh $(INST_LUADIR)/resty/auto-ssl/vendor/letsencrypt.sh
	install -m 644 lib/resty/auto-ssl/vendor/shell.lua $(INST_LUADIR)/resty/auto-ssl/vendor/shell.lua
	install -m 755 lib/resty/auto-ssl/vendor/sockproc $(INST_LUADIR)/resty/auto-ssl/vendor/sockproc

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/stamp-letsencrypt.sh-$(LETSENCRYPT_SH_VERSION): | $(BUILD_DIR)
	rm -f $(BUILD_DIR)/stamp-letsencrypt.sh-*
	curl -sSLo $(ROOT_DIR)/lib/resty/auto-ssl/vendor/letsencrypt.sh "https://raw.githubusercontent.com/lukas2511/letsencrypt.sh/$(LETSENCRYPT_SH_VERSION)/letsencrypt.sh"
	chmod +x $(ROOT_DIR)/lib/resty/auto-ssl/vendor/letsencrypt.sh
	touch $@

$(BUILD_DIR)/stamp-lua-resty-shell-$(LUA_RESTY_SHELL_VERSION): | $(BUILD_DIR)
	rm -f $(BUILD_DIR)/stamp-lua-resty-shell-*
	curl -sSLo $(ROOT_DIR)/lib/resty/auto-ssl/vendor/shell.lua "https://raw.githubusercontent.com/juce/lua-resty-shell/$(LUA_RESTY_SHELL_VERSION)/lib/resty/shell.lua"
	touch $@

$(BUILD_DIR)/stamp-sockproc-$(SOCKPROC_VERSION): | $(BUILD_DIR)
	rm -f $(BUILD_DIR)/stamp-sockproc-*
	cd $(BUILD_DIR) && curl -sSLo sockproc-$(SOCKPROC_VERSION).tar.gz "https://github.com/juce/sockproc/archive/$(SOCKPROC_VERSION).tar.gz"
	cd $(BUILD_DIR) && tar -xf sockproc-$(SOCKPROC_VERSION).tar.gz
	cd $(BUILD_DIR)/sockproc-$(SOCKPROC_VERSION) && make
	cp $(BUILD_DIR)/sockproc-$(SOCKPROC_VERSION)/sockproc $(ROOT_DIR)/lib/resty/auto-ssl/vendor/sockproc
	chmod +x $(ROOT_DIR)/lib/resty/auto-ssl/vendor/sockproc
	touch $@

#
# Testing
#

TEST_BUILD_DIR:=$(ROOT_DIR)/t/build
TEST_VENDOR_DIR:=$(ROOT_DIR)/t/vendor
TEST_TMP_DIR:=$(ROOT_DIR)/t/tmp
TEST_LUAROCKS_DIR:=$(TEST_VENDOR_DIR)/lib/luarocks/rocks
TEST_LUA_SHARE_DIR:=$(TEST_VENDOR_DIR)/share/lua/5.1
TEST_LUA_LIB_DIR:=$(TEST_VENDOR_DIR)/lib/lua/5.1
PATH:=$(TEST_BUILD_DIR)/bin:$(TEST_BUILD_DIR)/nginx/sbin:$(TEST_BUILD_DIR)/luajit/bin:$(PATH)

LUACHECK:=luacheck
LUACHECK_VERSION:=0.15.1-1

OPENSSL_VERSION:=1.0.2h
OPENSSL:=openssl-$(OPENSSL_VERSION)

OPENRESTY_VERSION:=1.9.15.1
OPENRESTY:=openresty-$(OPENRESTY_VERSION)

LUAROCKS_VERSION=2.3.0
LUAROCKS=luarocks-$(LUAROCKS_VERSION)

NGROK_VERSION:=2.0.25
NGROK:=ngrok-$(NGROK_VERSION)

define test_luarocks_install
	$(eval PACKAGE:=$($(1)))
	$(eval PACKAGE_VERSION:=$($(1)_VERSION))
	luarocks --tree=$(TEST_VENDOR_DIR) install $(PACKAGE) $(PACKAGE_VERSION)
	touch $@
endef

$(TEST_TMP_DIR):
	mkdir -p $@

$(TEST_VENDOR_DIR):
	mkdir -p $@

$(TEST_LUAROCKS_DIR)/$(LUACHECK)/$(LUACHECK_VERSION): $(TEST_TMP_DIR)/$(LUAROCKS)/.installed | $(TEST_VENDOR_DIR)
	$(call test_luarocks_install,LUACHECK)

$(TEST_TMP_DIR)/cpanm: | $(TEST_TMP_DIR)
	curl -o $@ -L http://cpanmin.us
	chmod +x $@
	touch $@

$(TEST_BUILD_DIR)/lib/perl5/Expect.pm: $(TEST_TMP_DIR)/cpanm
	$< -L $(TEST_BUILD_DIR) --reinstall --notest Expect@1.33
	touch $@

$(TEST_BUILD_DIR)/lib/perl5/Test/Nginx.pm: $(TEST_TMP_DIR)/cpanm
	$< -L $(TEST_BUILD_DIR) --reinstall --notest Test::Nginx@0.25
	touch $@

# Dependency for Expect.pm
$(TEST_BUILD_DIR)/lib/perl5/x86_64-linux-thread-multi/IO/Tty.pm: $(TEST_TMP_DIR)/cpanm
	$< -L $(TEST_BUILD_DIR) --reinstall --notest IO::Tty@1.12
	touch $@

UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
$(TEST_VENDOR_DIR)/$(NGROK)/ngrok: | $(TEST_TMP_DIR) $(TEST_VENDOR_DIR)
	curl -L -o $(TEST_TMP_DIR)/ngrok-$(NGROK_VERSION)-linux-amd64.tar.gz https://bin.equinox.io/a/2nnnbSQv68d/ngrok-$(NGROK_VERSION)-linux-amd64.tar.gz
	mkdir -p $(TEST_VENDOR_DIR)/$(NGROK)
	tar -C $(TEST_VENDOR_DIR)/$(NGROK) -xf $(TEST_TMP_DIR)/ngrok-$(NGROK_VERSION)-linux-amd64.tar.gz
endif
ifeq ($(UNAME), Darwin)
$(TEST_VENDOR_DIR)/$(NGROK)/ngrok: | $(TEST_TMP_DIR) $(TEST_VENDOR_DIR)
	curl -L -o $(TEST_TMP_DIR)/ngrok_$(NGROK_VERSION)-darwin-amd64.zip https://bin.equinox.io/a/jhmzSv18UeY/ngrok-$(NGROK_VERSION)-darwin-amd64.zip
	unzip $(TEST_TMP_DIR)/ngrok_$(NGROK_VERSION)-darwin-amd64.zip -d $(TEST_VENDOR_DIR)/$(NGROK)
endif

$(TEST_TMP_DIR)/$(OPENSSL): | $(TEST_TMP_DIR)
	cd $(TEST_TMP_DIR) && rm -rf openssl*
	cd $(TEST_TMP_DIR) && curl -L -O ftp://ftp.openssl.org/source/$(OPENSSL).tar.gz
	cd $(TEST_TMP_DIR) && tar -xf $(OPENSSL).tar.gz

$(TEST_TMP_DIR)/$(OPENRESTY)/.installed: $(TEST_TMP_DIR)/$(OPENSSL) | $(TEST_TMP_DIR)
	cd $(TEST_TMP_DIR) && rm -rf openresty*
	cd $(TEST_TMP_DIR) && curl -L -O https://openresty.org/download/$(OPENRESTY).tar.gz
	cd $(TEST_TMP_DIR) && tar -xf $(OPENRESTY).tar.gz
	cd $(TEST_TMP_DIR)/$(OPENRESTY) && ./configure --prefix=$(TEST_BUILD_DIR) --with-debug --with-openssl=$(TEST_TMP_DIR)/$(OPENSSL)
	cd $(TEST_TMP_DIR)/$(OPENRESTY) && make
	cd $(TEST_TMP_DIR)/$(OPENRESTY) && make install
	touch $@

$(TEST_TMP_DIR)/$(LUAROCKS)/.installed: $(TEST_TMP_DIR)/$(OPENRESTY)/.installed | $(TEST_TMP_DIR)
	cd $(TEST_TMP_DIR) && rm -rf luarocks*
	cd $(TEST_TMP_DIR) && curl -L -O http://luarocks.org/releases/$(LUAROCKS).tar.gz
	cd $(TEST_TMP_DIR) && tar -xf $(LUAROCKS).tar.gz
	cd $(TEST_TMP_DIR)/$(LUAROCKS) && ./configure \
		--prefix=$(TEST_BUILD_DIR)/luajit \
		--with-lua=$(TEST_BUILD_DIR)/luajit \
		--with-lua-include=$(TEST_BUILD_DIR)/luajit/include/luajit-2.1 \
		--lua-suffix=jit-2.1.0-beta2
	cd $(TEST_TMP_DIR)/$(LUAROCKS) && make bootstrap
	touch $@

test_dependencies: \
	$(TEST_LUAROCKS_DIR)/$(LUACHECK)/$(LUACHECK_VERSION) \
	$(TEST_VENDOR_DIR)/$(NGROK)/ngrok \
	$(TEST_TMP_DIR)/$(OPENRESTY)/.installed \
	$(TEST_TMP_DIR)/$(LUAROCKS)/.installed \
	$(TEST_BUILD_DIR)/lib/perl5/Expect.pm \
	$(TEST_BUILD_DIR)/lib/perl5/Test/Nginx.pm \
	$(TEST_BUILD_DIR)/lib/perl5/x86_64-linux-thread-multi/IO/Tty.pm

lint: test_dependencies
	LUA_PATH="$(TEST_LUA_SHARE_DIR)/?.lua;$(TEST_LUA_SHARE_DIR)/?/init.lua;;" LUA_CPATH="$(TEST_LUA_LIB_DIR)/?.so;;" $(TEST_VENDOR_DIR)/bin/luacheck lib

test: test_dependencies lint
	PATH=$(PATH) luarocks make ./lua-resty-auto-ssl-git-1.rockspec
	sudo mkdir -p /tmp/resty-auto-ssl-test-worker-perms
	sudo chown nobody /tmp/resty-auto-ssl-test-worker-perms
	pkill sockproc || true
	sudo pkill -U nobody sockproc || true
	sudo env TEST_NGINX_RESTY_AUTO_SSL_DIR=/tmp/resty-auto-ssl-test-worker-perms PATH=$(PATH) PERL5LIB=$(TEST_BUILD_DIR)/lib/perl5 prove t/worker_file_permissions.t
	sudo pkill -U nobody sockproc || true
	PATH=$(PATH) PERL5LIB=$(TEST_BUILD_DIR)/lib/perl5 prove `find $(ROOT_DIR)/t -maxdepth 1 -name "*.t" -not -name "worker_file_permissions.t"`

grind:
	env TEST_NGINX_USE_VALGRIND=1 TEST_NGINX_SLEEP=5 $(MAKE) test
