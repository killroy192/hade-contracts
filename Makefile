-include .env

.PHONY: all test clean install compile snapshot 

all: clean init-env install test

# Clean the repo
clean :; forge clean; rm -rf node_modules; rm .env

init-env :; touch .env;

# Local installation
install :; npm i && npx husky install

# CI installation
install-ci :; touch .env; npm ci

# Update Dependencies
forge-update:; forge update

# Compile contracts using hardhat
compile :; npx hardhat compile

# Run integfation & unit tests
test :; forge test -vvv; npx hardhat test

# Run particular unit test
unit :; forge test -vvv --match-contract $(contract) 

snapshot :; forge snapshot

format :; forge fmt src/; forge fmt test/

lint :; npx solhint src/**/*.sol

# Run hardhat local network (node)
node :; npx hardhat node

network?=hardhat
task?=help

# Run deploy task based on hardhat.config
deploy :; npx hardhat --network $(network) deploy-bundle

# Execute any available hardhat tast (inclusing custom)
run :; npx hardhat --network $(network) $(task) 

-include ${FCT_PLUGIN_PATH}/makefile-external
