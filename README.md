# Juliet Test Suite for C/C++

This is the Juliet Test Suite for C/C++ version 1.3 as published by NIST (https://samate.nist.gov/SARD/test-suites/112). The make-based build system for Unix-like platforms is extended to include targets for each contained CWE. These new targets lead to individual test cases being built in two version, good and bad.

## Makefile Template

The build is based on the `Makefile_per_CWE` template. The template applies multiple filters over the testcases to be built:

- Language: Only C testcases are considered. C++ testcases are excluded.
- Platform: Windows specific testcases are excluded.
- Random-based testcases: If the testcase depends on randomness during execution, as identified in the testcases name, the testcases is excluded.
- Input-awaiting testcases: For the purpose of simple automation we also excluded testcases whose functional component expects human input.
- Flow variants: Only the base variant (01) is selected for building.

## Usage

Substitute CWEXXX_DESCIPTION with the testcase subdirectory name and run:

```bash
$ cp Makefile_per_CWE testcases/CWEXXX_DESCRIPTION/Makefile
$ make CWEXXX_DESCRIPTION
```