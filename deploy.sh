#!/bin/bash

declare JSON_FILE=counter-contract-plan.json
declare -a bundleIDs=()
declare -a bundleFiles=()
declare script=""
declare permit=""

checkCounterFiles() {
    local files=(
        "counter-contract-permit.json"
        "counter-contract-plan.json"
        "counter-contract.js"
    )

    local all_files_exist=true
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "✅ $file exists."
        else
            echo "❌ $file is missing."
            all_files_exist=false
        fi
    done

    if $all_files_exist; then
        echo "All files are present."
    else
        echo "One or more files are missing."
        return 1
    fi
}

parsePlan() {
    script=$(jq -r '.script' "$JSON_FILE")
    permit=$(jq -r '.permit' "$JSON_FILE")

    if [[ -z "$script" || -z "$permit" ]]; then
        echo "Error: Failed to parse required fields from $JSON_FILE"
        return 1
    fi

    echo "Reading Bundle IDs..."
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            bundleIDs+=("${line}.json")
        fi
    done < <(jq -r '.bundles[].bundleID' "$JSON_FILE")

    echo "Reading Bundle Files..."
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            bundleFiles+=("${line}")
        fi
    done < <(jq -r '.bundles[].fileName' "$JSON_FILE")

}

echo "Running counterCoreEval.js using Agoric..."
agoric run counterCoreEval.js

checkCounterFiles
parsePlan

echo "bundleIDs: ${bundleIDs[*]}"
echo "bundleFiles: ${bundleFiles[*]}"
echo "script: \"$script\""
echo "permit: \"$permit\""
