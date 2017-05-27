unit_test_files = ts_crew.rb test_crew.rb test_release.rb

# skip network tests while we're not ready to update crew-test repository
# cmd_network_spec.rb  cmd_cleanup_spec.rb
rspec_files = cmd_simple_spec.rb cmd_install_spec.rb cmd_remove_spec.rb cmd_list_spec.rb \
              cmd_info_spec.rb cmd_update_spec.rb cmd_upgrade_spec.rb

rspec_cmd_tests = $(patubst cmd_%_spec,test-%,$(basename $(rspec_files)))

ifeq ($(OS),Windows_NT)
  host_os := windows
else
  host_os := $(shell uname -s | tr '[:upper:]' '[:lower:]')
endif

ifeq ($(origin CREW_NDK_DIR), undefined)
  CREW_NDK_DIR := $(realpath ../..)
endif

$(info Using CREW_NDK_DIR: $(CREW_NDK_DIR))

ifneq ($(wildcard $(CREW_NDK_DIR)/prebuilt/$(host_os)-x86_64),)
  TOOLS_DIR := $(CREW_NDK_DIR)/prebuilt/$(host_os)-x86_64
  PLATFORM := $(host_os)-x86_64
else ifeq ($(host_os),windows)
  TOOLS_DIR := $(CREW_NDK_DIR)/prebuilt/$(host_os)
  PLATFORM := $(host_os)
else
  TOOLS_DIR := $(CREW_NDK_DIR)/prebuilt/$(host_os)-x86
  PLATFORM := $(host_os)-x86
endif

ifeq ($(host_os),windows)
  ruby_prog := ruby.exe
else
  ruby_prog := ruby
endif

RUBY_DIR := $(TOOLS_DIR)/bin
RUBY     := $(RUBY_DIR)/$(ruby_prog)
RSPEC    := $(RUBY_DIR)/$(ruby_prog) $(RUBY_DIR)/rspec


ORIG_NDK_DIR   := $(CREW_NDK_DIR)
CREW_BASE_DIR  := crew
CREW_NDK_DIR   := ndk
SSL_CERT_FILE  := $(abspath ../etc/ca-certificates.crt)

ifeq ($(host_os),windows)
  RM           = rd
  RMFLAGS      = /s/q
  MKDIR        = md
  MKDIRFLAGS   =
  NDKSRC_DIR   = ndk\sources
  CACHE_DIR    = crew\cache
  FORMULA_DIR  = crew\formula\utilities
  CREW_TOOLS_DIR = $(CREW_NDK_DIR)\prebuilt\$(PLATFORM)
else
  RM             = rm
  MKDIR          = mkdir
  RMFLAGS        = -rf
  MKDIRFLAGS     = -p
  NDKSRC_DIR     = ndk/sources
  CACHE_DIR      = crew/cache
  FORMULA_DIR    = crew/formula/utilities
  CREW_TOOLS_DIR = $(CREW_NDK_DIR)/prebuilt/$(PLATFORM)
endif


export ORIG_NDK_DIR
export CREW_NDK_DIR
export CREW_TOOLS_DIR
export CREW_BASE_DIR
export SSL_CERT_FILE


.PHONY: all test clean clean-test-data env test-dirs test-data unit-tests rspec-tests $(rspec_cmd_tests)

all: test clean

test: test-data unit-tests rspec-tests

clean: clean-test-data
	$(RM) $(RMFLAGS) crew crew.git crew.net ndk

env:
	@echo RUBY_DIR       = $(RUBY_DIR)
	@echo ORIG_NDK_DIR   = $(ORIG_NDK_DIR)
	@echo CREW_NDK_DIR   = $(CREW_NDK_DIR)
	@echo CREW_TOOLS_DIR = $(CREW_TOOLS_DIR)
	@echo CREW_BASE_DIR  = $(CREW_BASE_DIR)

unit-tests: test-dirs
	$(RUBY) -I ../library ts_crew.rb

test-data: test-dirs
	$(RUBY) spec_prepare.rb

test-dirs:
	$(RUBY) spec_mkdirs.rb

clean-test-data:
	$(RUBY) spec_cleanup.rb

rspec-tests: test-data
	$(RSPEC) $(rspec_files)

test-%:
	$(RSPEC) cmd_$*_spec.rb

# todo: shell run with incorrect environment
shell:
	@PS1="[$(PS1) crew test] " bash

env:
