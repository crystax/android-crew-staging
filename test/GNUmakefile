unit_test_files = ts_crew.rb test_crew.rb test_release.rb

# skip network tests while we're not ready to update crew-test repository
# cmd_network_spec.rb
rspec_files = cmd_simple_spec.rb  \
              cmd_shasum.rb       \
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

ifeq ($(origin CREW_NDK_DIR), undefined)
  CREW_NDK_DIR = $(realpath ../..)
endif

$(info Using CREW_NDK_DIR: $(CREW_NDK_DIR))

ifneq ($(wildcard $(CREW_NDK_DIR)/prebuilt/$(host_os)-x86_64),)
  ORIG_TOOLS_DIR = $(CREW_NDK_DIR)/prebuilt/$(host_os)-x86_64
  PLATFORM = $(host_os)-x86_64
else
  ORIG_TOOLS_DIR = $(CREW_NDK_DIR)/prebuilt/$(host_os)
  PLATFORM = $(host_os)
endif

$(info Using ORIG_TOOLS_DIR: $(ORIG_TOOLS_DIR))
$(info Using PLATFORM: $(PLATFORM))

RUBY_DIR = $(ORIG_TOOLS_DIR)/bin
RUBY     = $(RUBY_DIR)/$(ruby_prog)
RSPEC    = $(RUBY_DIR)/$(ruby_prog) $(RUBY_DIR)/rspec

SSL_CERT_FILE  = $(abspath ../etc/ca-certificates.crt)

export ORIG_TOOLS_DIR
export SSL_CERT_FILE


.PHONY: all test clean test-data unit-tests rspec-tests $(rspec_cmd_tests)

all: test clean

test: unit-tests rspec-tests

clean:
	$(RUBY) spec_cleanup.rb
	$(RM) crew crew.git crew.net ndk

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
