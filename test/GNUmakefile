unit_test_files = ts_crew.rb test_crew.rb test_release.rb

# skip network tests while we're not ready to update crew-test repository
# cmd_network_spec.rb
rspec_files = cmd_simple_spec.rb  \
              cmd_shasum_spec.rb  \
              cmd_install_spec.rb \
              cmd_remove_spec.rb  \
              cmd_list_spec.rb    \
              cmd_info_spec.rb    \
              cmd_update_spec.rb  \
              cmd_upgrade_spec.rb \
              cmd_cleanup_spec.rb \
              cmd_common_spec.rb

rspec_cmd_tests = $(patubst cmd_%_spec,test-%,$(basename $(rspec_files)))

ifeq ($(OS),Windows_NT)
  host_os = windows
  ruby_prog = ruby.exe
  RM = rd /s/q
else
  host_os = $(shell uname -s | tr '[:upper:]' '[:lower:]')
  ruby_prog = ruby
  RM = rm -rf
endif

CREW_NDK_DIR       = $(shell ../crew env --ndk-dir)
CREW_TOOLS_DIR     = $(shell ../crew env --tools-dir)
CREW_PLATFORM_NAME = $(shell ../crew env --platform-name)

$(info Using CREW_NDK_DIR: $(CREW_NDK_DIR))
$(info Using ORIG_TOOLS_DIR: $(CREW_TOOLS_DIR))
$(info Using PLATFORM: $(CREW_PLATFORM_NAME))

RUBY_DIR = $(CREW_TOOLS_DIR)/bin
RUBY     = $(RUBY_DIR)/$(ruby_prog)
RSPEC    = $(RUBY_DIR)/$(ruby_prog) $(RUBY_DIR)/rspec --no-color

SSL_CERT_FILE  = $(abspath ../etc/ca-certificates.crt)

TOOLS = cloog expat gcc gmp isl libedit libgit2 libssh2 llvm make mpc mpfr nawk ndk_base ndk_depends ndk_stack openssl ppl python toolbox yasm zlib

export SSL_CERT_FILE
export CREW_NDK_DIR
export CREW_TOOLS_DIR
export CREW_PLATFORM_NAME




.PHONY: all test clean test-data unit-tests rspec-tests $(rspec_cmd_tests)

all: test clean

test: unit-tests rspec-tests

clean:
	$(RM) crew crew.git crew.net ndk ndk.copy pkg.cache src.cache tmp www
	$(RM) .testdataprepared data/releases_info.rb $(patsubst %,data/%*.rb,$(TOOLS))

unit-tests:
	$(RUBY) -I ../library ts_crew.rb

test-data:
	$(RUBY) spec_prepare.rb

rspec-tests: test-data
	$(RSPEC) $(rspec_files)

test-%:
	$(RSPEC) cmd_$*_spec.rb

# todo: shell run with incorrect environment
shell:
	@PS1="[$(PS1) crew test] " bash
