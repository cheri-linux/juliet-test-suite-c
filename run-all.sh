#!/bin/sh

SCRIPT_DIR=$(dirname $(realpath "$0"))
TIMEOUT="5s"
PRELOAD_PATH=""
TEST_FILTER_REGEX=""
GREPFLAGS="-vE"
BAD_ONLY=""
GOOD_ONLY=""
MEM_SAFE_CWE=""

GLOBAL_SUCCESS_COUNTER=0
GLOBAL_TIMEOUT_COUNTER=0
GLOBAL_TESTCASE_COUNTER=0
GLOBAL_VIOLATION_COUNTER=0
GLOBAL_SEGFAULT_COUNTER=0
GLOBAL_MALLOC_ERROR_COUNTER=0
GLOBAL_GENERIC_ERROR_COUNTER=0
GLOBAL_ABORT_COUNTER=0
GLOBAL_UNKNOWN_COUNTER=0

skip_count=0
for x ; do

  case "$x" in
  -v)
    GREPFLAGS="-vE"
    skip_count=$((skip_count+1))
    shift
    ;;
  -h)
    echo "Usage ${0} [-v] [-h] [-bo] [-go] [-memsafe] parent_dir timeout filter_regex"
    echo
    echo " parent_dir       The parent directory containing the per CWE subdirectories, default the cwd"
    echo " timeout          The timeout in seconds after which a test case is terminated, default=1s"
    echo " filter_regex     The use this regex to filter the CWE's testcases, default=\".*\""
    echo " -h               This help page"
    echo " -v               Invert matching of the filter, i.e., exclude all testcases with names matching the regex"
    echo " -bo              Run only the bad code test case executables"
    echo " -go              Run only the good code test case executables"
    echo " -memsafe         Run only the CWEs related to memory safety: 121, 122, 124, 126, 127, 476, 680, 401, 415, 416, 562."
    echo "                  overrides any given parent directory."
    echo
    echo " All parameters are optional; The flags -h, -v, -bo, -go, -memsafe are non-positional amoung themselves positional but can be left out; the other optional arguments
     cannot be skipped if a later positional argument is given"
    exit 1
    ;;
  -bo)
    echo "Running bad code only"
    BAD_ONLY="y"
    skip_count=$((skip_count+1))
    shift
    ;;
  -go)
    echo "Running good code only"
    GOOD_ONLY="y"
    skip_count=$((skip_count+1))
    shift
    ;;
  -memsafe)
    echo "Running only memory safety related CWEs"
    MEM_SAFE_CWE="y"
    skip_count=$((skip_count+1))
    shift
    ;;
  *)
    ;;
  esac
done

if [ $# -ge 1 ] ; then
  PARENT_DIR="$1"
else
  if [ -z "$MEM_SAFE_CWE" ] ; then
    echo "No parent dir specified - running tests in this directory"
    echo "See -h option for more help"
  fi
  # exit 1
fi

if [ $# -ge 2 ] ; then
  TIMEOUT="$2"
fi

if [ $# -ge 3 ] ; then
  TEST_FILTER_REGEX="$3"
fi

# echo "grep ${GREPFLAGS} \"${TEST_FILTER_REGEX}\""

# parameter 1: the CWE directory corresponding to the tests
# parameter 2: the type of tests to run (should be "good" or "bad")
run_tests()
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
  cd "${1}" # change directory in case of test-produced output files
  echo "========== STARTING TEST ${1}/${2} $(date) ==========" >> "${1}/${2}.run"
  TESTCASES=$(ls ${1}/${2})
  for TESTCASE in ${TESTCASES} ; do
    local TESTCASE_PATH="${1}/${2}/${TESTCASE}"
    echo "> ${TESTCASE_PATH}"
    busybox timeout "${TIMEOUT}" "${TESTCASE_PATH}"
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

  GLOBAL_SUCCESS_COUNTER=$((GLOBAL_SUCCESS_COUNTER+SUCCESS_COUNTER))
  GLOBAL_TIMEOUT_COUNTER=$((GLOBAL_TIMEOUT_COUNTER+TIMEOUT_COUNTER))
  GLOBAL_TESTCASE_COUNTER=$((GLOBAL_TESTCASE_COUNTER+TESTCASE_COUNTER))
  GLOBAL_VIOLATION_COUNTER=$((GLOBAL_VIOLATION_COUNTER+VIOLATION_COUNTER))
  GLOBAL_SEGFAULT_COUNTER=$((GLOBAL_SEGFAULT_COUNTER+SEGFAULT_COUNTER))
  GLOBAL_MALLOC_ERROR_COUNTER=$((GLOBAL_MALLOC_ERROR_COUNTER+MALLOC_ERROR_COUNTER))
  GLOBAL_GENERIC_ERROR_COUNTER=$((GLOBAL_GENERIC_ERROR_COUNTER+GENERIC_ERROR_COUNTER))
  GLOBAL_ABORT_COUNTER=$((GLOBAL_ABORT_COUNTER+ABORT_COUNTER))
  GLOBAL_UNKNOWN_COUNTER=$((GLOBAL_UNKNOWN_COUNTER+UNKNOWN_COUNTER))

  cd "${CWD}"
}

CWE_LIST="TEST"
if [ -z "$MEM_SAFE_CWE" ] ; then 
  CWE_LIST=`ls $PARENT_DIR | grep CWE`
else
  CWE_LIST="CWE121 CWE122 CWE124 CWE126 CWE127 CWE476 CWE680 CWE401 CWE415 CWE416 CWE562"
fi

sleep 1

if [ -z "$BAD_ONLY" ] ; then
  echo "Running good code ..."
  sleep 1
  for CWE_DIR in $CWE_LIST; do
    run_tests "${SCRIPT_DIR}/${CWE_DIR}" "good"
  done

  echo
  echo ">#####################################################"
  echo ">#                 Summary -- good                     "
  echo "># ================================================== "
  echo "># Total tests run: ${GLOBAL_TESTCASE_COUNTER}"
  echo "># Normal exits: ${GLOBAL_SUCCESS_COUNTER}"
  echo "># Timedout tests: ${GLOBAL_TIMEOUT_COUNTER}"
  echo "># Segmentation faults: ${GLOBAL_SEGFAULT_COUNTER}"
  echo "># Violations (SIGILL): ${GLOBAL_VIOLATION_COUNTER}"
  echo "># Explicit Allocation Error: ${GLOBAL_MALLOC_ERROR_COUNTER}"
  echo "># Explicit Error Handling: ${GLOBAL_GENERIC_ERROR_COUNTER}"
  echo "># Aborts (SIGABRT): ${GLOBAL_ABORT_COUNTER}"
  echo "># Unknown exit codes: ${GLOBAL_UNKNOWN_COUNTER}"
  echo ">#####################################################"
  echo

  GLOBAL_SUCCESS_COUNTER=0
  GLOBAL_TIMEOUT_COUNTER=0
  GLOBAL_TESTCASE_COUNTER=0
  GLOBAL_VIOLATION_COUNTER=0
  GLOBAL_SEGFAULT_COUNTER=0
  GLOBAL_MALLOC_ERROR_COUNTER=0
  GLOBAL_GENERIC_ERROR_COUNTER=0
  GLOBAL_ABORT_COUNTER=0
  GLOBAL_UNKNOWN_COUNTER=0
fi
if [ -z "$GOOD_ONLY" ] ; then
  echo "Running bad code ..."
  sleep 1
  for CWE_DIR in $CWE_LIST; do
    run_tests "${SCRIPT_DIR}/${CWE_DIR}" "bad"
  done

  echo
  echo ">#####################################################"
  echo ">#                 Summary -- bad                     "
  echo "># ================================================== "
  echo "># Total tests run: ${GLOBAL_TESTCASE_COUNTER}"
  echo "># Normal exits: ${GLOBAL_SUCCESS_COUNTER}"
  echo "># Timedout tests: ${GLOBAL_TIMEOUT_COUNTER}"
  echo "># Segmentation faults: ${GLOBAL_SEGFAULT_COUNTER}"
  echo "># Violations (SIGILL): ${GLOBAL_VIOLATION_COUNTER}"
  echo "># Explicit Allocation Error: ${GLOBAL_MALLOC_ERROR_COUNTER}"
  echo "># Explicit Error Handling: ${GLOBAL_GENERIC_ERROR_COUNTER}"
  echo "># Aborts (SIGABRT): ${GLOBAL_ABORT_COUNTER}"
  echo "># Unknown exit codes: ${GLOBAL_UNKNOWN_COUNTER}"
  echo ">#####################################################"
  echo
fi