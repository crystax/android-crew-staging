@echo off

call run-tests.cmd clean
call run-tests.cmd test-data
call run-tests.cmd test-simple
call run-tests.cmd test-shasum
