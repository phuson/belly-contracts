# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

all: clean remove install update solc build dappbuild

# Install proper solc version.
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_13

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf ../../.gitmodules && rm -rf ../../.git/modules/* && rm -rf lib && touch ../../.gitmodules && git add . && git commit -m "modules"

# Install the Modules
install :; forge install foundry-rs/forge-std && forge install openzeppelin/openzeppelin-contracts

# Update Dependencies
update:; forge update

# Builds
build  :; forge clean && forge build --optimize --optimizer-runs 1000000
dappbuild :; dapp build

# chmod scripts
scripts :; chmod +x ./scripts/*

# Tests
tests:; forge clean && forge test --optimize --optimizer-runs 1000000 -vvv  # --ffi # enable if you need the `ffi` cheat code on HEVM

testgas:; forge clean && forge test --optimize --optimizer-runs 1000000 -vv --gas-report  # --ffi # enable if you need the `ffi` cheat code on HEVM

# Lints
lint :; prettier --write src/**/*.sol && prettier --write src/*.sol

# Generate Gas Snapshots
snapshot :; forge clean && forge snapshot --optimize --optimizer-runs 1000000

# Fork Mainnet With Hardhat
mainnet-fork :; npx hardhat node --fork ${ETH_MAINNET_RPC_URL}

# Rename all instances of femplate with the new repo name
rename :; chmod +x ./scripts/* && ./scripts/rename.sh