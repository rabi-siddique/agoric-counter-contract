#!/bin/bash

declare createVault=false
declare dockerFlag=true
declare containerID=$(docker ps -q | head -n 1)
declare agops="/usr/src/agoric-sdk/packages/agoric-cli/bin/agops"

declare JSON_FILE=counter-contract-plan.json
declare CHAINID=agoriclocal
declare GAS_ADJUSTMENT=1.2
declare SIGN_BROADCAST_OPTS="--keyring-backend=test --chain-id=$CHAINID --gas=auto --gas-adjustment=$GAS_ADJUSTMENT --yes -b block"
declare -a bundleIDs=()
declare -a bundleFiles=()
declare script=""
declare permit=""
declare walletName=gov1

if [[ "$1" == "-v" ]]; then
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

execCmd() {
    local cmd="$1"
    if $dockerFlag; then
        docker exec -it "$containerID" bash -c "$cmd"
    else
        bash -c "$cmd"
    fi
}

openVaultsAndExecuteOffer() {
    local wantMinted=450
    local giveCollateral=90
    local walletAddress="agoric1ee9hr0jyrxhy999y755mp862ljgycmwyp4pl7q"
    local openVaultCommand="${agops} vaults open --wantMinted ${wantMinted} --giveCollateral ${giveCollateral} > /tmp/want-ist.json"
    local executeOfferCommand="${agops} perf satisfaction --executeOffer /tmp/want-ist.json --from $walletAddress --keyring-backend=test"

    if [[ $createVault == true && $walletAddress ]]; then
        echo "Creating the vault..."
        execCmd "$openVaultCommand"
        sleep 5
        echo "Executing the offer..."
        execCmd "$executeOfferCommand"
    else
        echo "Vault not created"
    fi
}

installAllBundles() {
    for b in "${bundleIDs[@]}"; do
        local installCommand="cd /usr/src && "
        installCommand+="echo 'Installing $b' && "
        installCommand+="ls -sh '$b' && "
        installCommand+="agd tx swingset install-bundle --compress '@$b' "
        installCommand+="--from $walletName -bblock $SIGN_BROADCAST_OPTS"

        echo "Executing installation for bundle $b"
        execCmd "$installCommand"
        sleep 5
    done
}

acceptProposal() {
    echo "Submitting proposal to evaluate $script"
    local submitCommand="cd /usr/src && agd tx gov submit-proposal swingset-core-eval $permit $script "
    submitCommand+="--title='Replace EC Committee and Charter' --description='Evaluate $script' "
    submitCommand+="--deposit=10000000ubld --from $walletName $SIGN_BROADCAST_OPTS -o json"
    execCmd "$submitCommand"

    sleep 5

    local queryCommand="cd /usr/src && agd query gov proposals --output json | jq -c '[.proposals[] | "
    queryCommand+="if .proposal_id == null then .id else .proposal_id end | tonumber] | max'"

    local LATEST_PROPOSAL=$(execCmd "$queryCommand" | sed 's/\x1b\[[0-9;]*m//g' | tr -d '[:space:]')
    echo "Voting on proposal ID $LATEST_PROPOSAL"
    # Filter out unnecessary ANSI escape sequences
    echo "$LATEST_PROPOSAL" | od -A n -t x1

    local voteCommand="agd tx gov vote $LATEST_PROPOSAL yes --from=validator $SIGN_BROADCAST_OPTS"
    execCmd "$voteCommand"

    echo "Fetching details for proposal ID $LATEST_PROPOSAL"
    local detailsCommand="agd query gov proposals --output json | jq -c "
    detailsCommand+="'.proposals[] | select(.proposal_id == \"$LATEST_PROPOSAL\" or .id == \"$LATEST_PROPOSAL\") "
    detailsCommand+="| [.proposal_id or .id, .voting_end_time, .status]'"

    execCmd "$detailsCommand"
}

if ! command -v jq &>/dev/null; then
    echo "jq is not installed. Installing jq..."
    execCmd "apt-get install -y jq"
fi

echo "Running counterBuilder.js using Agoric..."
agoric run counterBuilder.js

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

openVaultsAndExecuteOffer
installAllBundles
acceptProposal
