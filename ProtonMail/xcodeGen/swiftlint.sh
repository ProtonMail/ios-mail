if [[ ! -z "${SWIFT_SUPPRESS_WARNINGS}" ]] && [ "${SWIFT_SUPPRESS_WARNINGS}" == "YES" ]; then
  # variable exists and value is YES, skip linter for CI 
  exit 0
fi

xcodeGen/run_with_mint.sh swiftlint --config "swiftlint/swiftlint.yml"
