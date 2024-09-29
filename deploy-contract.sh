# Create a vault for gov1 to get enough ISTs to install bundles
wantMinted=450
giveCollateral=90
walletName=gov1

if [ "$1" -eq 1 ]; then
  agops vaults open --wantMinted ${wantMinted} --giveCollateral ${giveCollateral} > /tmp/want-ist.json
  sleep 5
  agops perf satisfaction --executeOffer /tmp/want-ist.json --from $walletName --keyring-backend=test
else
  echo "Skipping creation of vault"
fi


# Generate Bundles
mkdir -p bundles
FILENAME=counterBuilder.js
(agoric run $FILENAME A3P_INTEGRATION) > /tmp/,run.log
node parseProposals.mjs < /tmp/,run.log \
  | jq -r '.bundles[]' | sort -u > bundles/bundle-list

# Install Bundles 
# Make sure to get enough ISTs for gov1 by creating a vault
# I created a vault from dapp-inter ==> You can create from CLI too
install_bundle() {
  ls -sh "$1"
  agd tx swingset install-bundle --compress "@$1" \
    --from gov1 --keyring-backend=test --gas=auto --gas-adjustment=1.2 \
    --chain-id=agoriclocal -bblock --yes -o json
}

for b in $(cat bundles/bundle-list); do 
  echo Installing $b
  install_bundle $b
  sleep 5
done

# Submit Proposal
PERMIT=bundles/start-counter-permit.json
SCRIPT=bundles/start-counter.js

agd tx gov submit-proposal swingset-core-eval $PERMIT $SCRIPT \
  --title="Replace EC Committee and Charter" --description="Evaluate $SCRIPT" \
  --deposit=10000000ubld --gas=auto --gas-adjustment=1.2 \
  --from $walletName --chain-id agoriclocal --keyring-backend=test \
  --yes -b block

sleep 3

# Accept Proposal
LATEST_PROPOSAL=$(agd query gov proposals --output json | jq -c '[.proposals[] | if .proposal_id == null then .id else .proposal_id end | tonumber] | max')
PROPOSAL=$LATEST_PROPOSAL
VOTE_OPTION=yes
CHAINID=agoriclocal
GAS_ADJUSTMENT=1.2
CONTAINER_ID=$(docker ps -q) # Assuming you're dynamically getting the container ID

# Construct the SIGN_BROADCAST_OPTS correctly
SIGN_BROADCAST_OPTS="--keyring-backend=test --chain-id=$CHAINID --gas=auto --gas-adjustment=$GAS_ADJUSTMENT --yes -b block"

# Execute the command in the Docker container
docker exec -it $CONTAINER_ID bash -c \
  "agd tx gov vote $PROPOSAL $VOTE_OPTION --from=validator $SIGN_BROADCAST_OPTS -o json > tx.json"

# View Proposal
agd query gov proposals --output json \
  | jq -c '.proposals[] | [if .proposal_id == null then .id else .proposal_id end,.voting_end_time,.status]'

