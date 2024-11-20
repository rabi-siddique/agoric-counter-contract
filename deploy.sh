#!/bin/bash

declare JSON_FILE="$1"
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

# Generate bundles
echo "Running counterCoreEval.js using Agoric..."
agoric run counterCoreEval.js

# Check existence of files
checkCounterFiles
