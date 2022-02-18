test:
	@echo "Running three test examples. See tests/ for more. Expects tests to terminate with 'Done' at the end"
	cd ./tests && ./test_zero_exit.sh ; echo
	cd ./tests && ./test_crash.sh ; echo
	cd ./tests && ./test_nc.sh ; echo
	@echo "Tests Passed."
install:
	if [ ! -z ${GOPATH} ]; then cp par ${GOPATH}/bin/ ; else echo "Failed to install. Expected GOPATH to be set"; fi
clobber:
	git clean -df
