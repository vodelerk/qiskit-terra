# Copyright 2017, IBM.
#
# This source code is licensed under the Apache License, Version 2.0 found in
# the LICENSE.txt file in the root directory of this source tree.

.PHONY: env lint test doc test_record test_mock test_ci

# Dependencies need to be installed on the Anaconda virtual environment.
env:
	if test $(findstring qiskitenv, $(shell conda info --envs | tr '[:upper:]' '[:lower:]')); then \
		bash -c "source activate Qiskitenv;pip install -r requirements.txt"; \
	else \
		conda create -y -n Qiskitenv python=3; \
		bash -c "source activate Qiskitenv;pip install -r requirements.txt"; \
	fi;

# Ignoring generated ones with .py extension.
lint:
	pylint -rn qiskit test

style:
	pycodestyle --max-line-length=100 qiskit test

# Use the -s (starting directory) flag for "unittest discover" is necessary,
# otherwise the QuantumCircuit header will be modified during the discovery.
test:
	python3 -m unittest discover -s test -v

test_mock:
	env QISKIT_TESTS=mock_online python3 -m unittest discover -s test -v

test_recording:
	-rm test/cassettes/*
	env QISKIT_TESTS=rec python3 -m unittest discover -s test -v

test_ci:
	stestr run --concurrency 2

profile:
	python3 -m unittest discover -p "profile*.py" -v

coverage:
	coverage3 run --source qiskit -m unittest discover -s test -q
	coverage3 report

doc:
	export PYTHONPATH=$(PWD); \
	for LANGUAGE in "." "de" "ja"; do \
		better-apidoc -f -o doc/$$LANGUAGE/_autodoc --no-toc --private --maxdepth=5 --separate --templates=doc/_templates/better-apidoc qiskit "qiskit/extensions/standard/[a-z]*"; \
		sphinx-autogen -t doc/_templates doc/$$LANGUAGE/_autodoc/*; \
		make -C doc -e BUILDDIR="_build/$$LANGUAGE" -e SOURCEDIR="./$$LANGUAGE" html; \
	done

coverage_erase:
	coverage erase

clean: coverage_erase
	make -C doc clean
	make -C doc -e BUILDDIR="_build/de" -e SOURCEDIR="./de" clean
	make -C doc -e BUILDDIR="_build/ja" -e SOURCEDIR="./ja" clean
	rm -f test/python/test_latex_drawer.tex test/python/test_qasm_python_simulator.pdf \
		test/python/test_save.json test/python/test_teleport.tex
