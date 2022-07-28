#!/bin/sh

SCRIPT_DIR=$(dirname $(realpath "$0"))
CWE_DIR=""
TIMEOUT="1s"
TEST_FILTER_REGEX=".*"
GREPFLAGS="-E"

# read args
# handle optional

for x ; do
  case "$x" in
  -v)
    GREPFLAGS="-vE"
    shift
    ;;
  -h)
    echo "Usage ${0} [-v] [-h] CWEXXX timeout filter_regex"
    echo
    echo " CWEXXX           The CWE XXX to be tested"
    echo " timeout          The timeout in seconds after which a test case is terminated, default=1s"
    echo " filter_regex     The use this regex to filter the CWE's testcases, default=\".*\""
    echo " -h               This help page"
    echo " -v               Invert matching of the filter, i.e., exclude all testcases with names matching the regex"
    echo
    echo " All parameters except the CWE are optional; The flags -h and -v are positional; the other optional arguments
    cannot be skipped if a later positional argument is given"
    exit 1
    ;;
  *)
    ;;
  esac
done

echo $#

if [ $# -ge 1 ]
then
  CWE_DIR="$1"
else
  echo "No CWE path specified - not running tests"
  echo "See -h option for more help"
  exit 1
fi

if [ $# -ge 2 ]
then
  TIMEOUT="$2"
fi

if [ $# -ge 3 ]
then
  TEST_FILTER_REGEX="$3"
fi

# read positional

run_tests_for_cwe ()
{
  local SUCCESS_COUNTER=0
  local TIMEOUT_COUNTER=0
  local TESTCASE_COUNTER=0
  local VIOLATION_COUNTER=0
  local SEGFAULT_COUNTER=0
  local MALLOC_ERROR_COUNTER=0
  local GENERIC_ERROR_COUNTER=0
  local ABORT_COUNTER=0
  local UNKNOWN_COUNTER=0

  local CWD=$(pwd)

  cd $1

  echo "========== STARTING TEST ${1}/${2} $(date) ==========" >> "${1}/${2}.run"
  for TESTCASE in $(ls -1 "${1}/${2}" | grep "${GREPFLAGS}" "${TEST_FILTER_REGEX}"); do
    local TESTCASE_PATH="${1}/${2}/${TESTCASE}"
    echo "> ${TESTCASE_PATH}"
    if [ ! -z "${PRELOAD_PATH}" ]
    then
      busybox timeout "${TIMEOUT}"  "${TESTCASE_PATH}"
    else
      busybox timeout "${TIMEOUT}" "${TESTCASE_PATH}"
    fi
    RETURN_CODE=$?
    echo "${TESTCASE_PATH} ${RETURN_CODE}" >> "${1}/${2}.run"

    case ${RETURN_CODE} in
    0)
      SUCCESS_COUNTER=$((SUCCESS_COUNTER+1))
      ;;
    143)
      TIMEOUT_COUNTER=$((TIMEOUT_COUNTER+1))
      ;;
    139)
      SEGFAULT_COUNTER=$((SEGFAULT_COUNTER+1))
      ;;
    132)
      VIOLATION_COUNTER=$((VIOLATION_COUNTER+1))
      ;;
    255)
      MALLOC_ERROR_COUNTER=$((MALLOC_ERROR_COUNTER+1))
      ;;
    1)
      GENERIC_ERROR_COUNTER=$((GENERIC_ERROR_COUNTER+1))
      ;;
    134)
      ABORT_COUNTER=$((ABORT_COUNTER+1))
      ;;
    *)
      UNKNOWN_COUNTER=$((UNKNOWN_COUNTER+1))
      echo "Unknown return code ${RETURN_CODE}"
    esac
    TESTCASE_COUNTER=$((TESTCASE_COUNTER+1))
  done

  echo
  echo "#####################################################"
  echo "#                      Summary                       "
  echo "# ================================================== "
  echo "# CWE: ${1} -- ${2}"
  echo "# Filter: ${GREPFLAGS} \"${TEST_FILTER_REGEX}\""
  echo "# Total tests run: ${TESTCASE_COUNTER}"
  echo "# Normal exits: ${SUCCESS_COUNTER}"
  echo "# Timedout tests: ${TIMEOUT_COUNTER}"
  echo "# Segmentation faults: ${SEGFAULT_COUNTER}"
  echo "# Violations (SIGILL): ${VIOLATION_COUNTER}"
  echo "# Explicit Allocation Error: ${MALLOC_ERROR_COUNTER}"
  echo "# Explicit Error Handling: ${GENERIC_ERROR_COUNTER}"
  echo "# Aborts (SIGABRT): ${ABORT_COUNTER}"
  echo "# Unknown exit codes: ${UNKNOWN_COUNTER}"
  echo "#####################################################"
  echo

  cd $CWD

}

# run per CWE tests
run_tests_for_cwe "${SCRIPT_DIR}/${CWE_DIR}" "good"
run_tests_for_cwe "${SCRIPT_DIR}/${CWE_DIR}" "bad"

