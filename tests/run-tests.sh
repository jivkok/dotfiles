#!/usr/bin/env bash
set -euo pipefail

# Test runner.
#
# Environments:
#   - Always runs tests locally.
#   - Reads tests/.testenv to discover Docker environments: any variable matching
#     *_DOCKER_IMAGE with a non-empty value points to a built Docker image to test in.
#
# Test discovery:
#   - Tests are files matching tests/test-cases/test-*.sh.
#
# Execution:
#   - Runs all discovered tests in each environment (local first, then Docker images).
#   - Fails immediately on any test failure.

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testenv_file="${tests_root}/.testenv"
test_cases_dir="${tests_root}/test-cases"

mapfile -t test_files < <(find "${test_cases_dir}" -name 'test-*.sh' | sort)

if [[ ${#test_files[@]} -eq 0 ]]; then
  echo "No test files found in ${test_cases_dir}."
  exit 0
fi

run_local() {
  echo
  echo "==> Environment: local"
  for test_file in "${test_files[@]}"; do
    echo
    echo "Test file: ${test_file##*/}"
    bash "${test_file}"
  done
}

run_in_docker() {
  local image="$1"
  local container_tests="/home/test/dotfiles/tests"
  local container_test_cases="${container_tests}/test-cases"
  echo
  echo "==> Environment: Docker image ${image}"
  for test_file in "${test_files[@]}"; do
    local test_name="${test_file##*/}"
    echo
    echo "Test file: ${test_name}"
    docker run --rm \
      -v "${tests_root}:${container_tests}:ro" \
      "${image}" bash -li "${container_test_cases}/${test_name}"
  done
}

run_local

if [[ -f "${testenv_file}" ]]; then
  while IFS='=' read -r key value; do
    [[ "$key" =~ _DOCKER_IMAGE$ ]] || continue
    [[ -n "$value" ]] || continue
    run_in_docker "$value"
  done < "${testenv_file}"
fi

echo
echo "==> All tests passed."
