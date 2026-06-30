#!/usr/bin/env bash
# Validate a JIT access request against OPA policies
# Usage: ./scripts/validate.sh <path-to-request.yaml>

set -euo pipefail

REQUEST_FILE="${1:-}"

if [ -z "$REQUEST_FILE" ]; then
    echo "Usage: $0 <path-to-request.yaml>"
    echo "Example: $0 requests/20250630-alice-prod-read.yaml"
    exit 1
fi

if [ ! -f "$REQUEST_FILE" ]; then
    echo "Error: File not found: $REQUEST_FILE"
    exit 1
fi

echo "Validating $REQUEST_FILE..."

# Check OPA is installed
if ! command -v opa &> /dev/null; then
    echo "Error: OPA CLI not found. Install from https://www.openpolicyagent.org/docs/latest/#running-opa"
    exit 1
fi

# Validate the request
opa eval -d policies/ -i "$REQUEST_FILE" 'data.jit.result' --format pretty

echo ""
echo "Checking constraints individually:"

for constraint in duration justification emergency sod role_tiering time_restricted; do
    echo -n "  $constraint: "
    if opa eval -d policies/ -i "$REQUEST_FILE" "data.jit.constraints.$constraint.check" --format raw 2>/dev/null | grep -q "true"; then
        echo "PASS"
    else
        echo "FAIL"
    fi
done

echo ""
echo "Validation complete."
