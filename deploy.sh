#!/bin/bash

declare createVault=false
declare containerID=$(docker ps -q | head -n 1)

declare JSON_FILE=counter-contract-plan.json
declare -a bundleIDs=()
declare -a bundleFiles=()
declare script=""
declare permit=""

if [[ "$2" == "-v" ]]; then
    createVault=true
fi

if [ -z "$containerID" ]; then
    echo "No Docker container running. Exiting."
    exit 1
fi

checkCounterFiles() {
    local files=(
        "counter-contract-permit.json"
        "counter-contract-plan.json"
        "counter-contract.js"
    )

    local allFilesExist=true
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            echo "✅ $file exists."
        else
            echo "❌ $file is missing."
            allFilesExist=false
        fi
    done

    if $allFilesExist; then
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

copyFilesToContainer() {
    targetDir="/usr/src/"

    docker cp "$script" "$containerID":"$targetDir"
    docker cp "$permit" "$containerID":"$targetDir"
    docker cp "$JSON_FILE" "$containerID":"$targetDir"

    for file in "${bundleFiles[@]}"; do
        if [[ -f "$file" ]]; then
            echo "Copying $file to container $containerID..."
            docker cp "$file" "$containerID":"$targetDir"
        else
            echo "Warning: File $file not found."
        fi
    done
}

setupAgops() {
    local setupCommand="
        echo 'Setting AGOPS';
        export PATH=\\\"\$PATH:/usr/src/agoric-sdk/packages/agoric-cli/bin\\\";"

    docker exec -it "$containerID" /bin/bash -c "$setupCommand"
}

echo "Running counterCoreEval.js using Agoric..."
agoric run counterCoreEval.js

echo "Checking files..."
checkCounterFiles

echo "Parsing plan..."
parsePlan

echo "bundleIDs: ${bundleIDs[*]}"
echo "bundleFiles: ${bundleFiles[*]}"
echo "script: \"$script\""
echo "permit: \"$permit\""

echo "Copying files..."
copyFilesToContainer

echo "Setting up agops..."
setupAgops
