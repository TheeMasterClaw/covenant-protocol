# COVENANT Protocol Makefile

.PHONY: install compile test deploy local-demo clean

# Install dependencies
install:
	npm install --legacy-peer-deps

# Compile contracts
compile:
	npx hardhat compile

# Run tests
test:
	npx hardhat test

# Run tests with gas report
test-gas:
	REPORT_GAS=true npx hardhat test

# Start local node
node:
	npx hardhat node

# Deploy to local network
local-deploy:
	npx hardhat run scripts/deploy.js --network hardhat

# Run demo on local network
local-demo:
	npx hardhat run scripts/demo.js --network hardhat

# Deploy to X Layer testnet
testnet-deploy:
	npx hardhat run scripts/deploy.js --network xlayerTestnet

# Deploy to X Layer mainnet
mainnet-deploy:
	npx hardhat run scripts/deploy.js --network xlayer

# Verify contracts on OKLink
verify:
	npx hardhat verify --network xlayer DEPLOYED_CONTRACT_ADDRESS

# Clean build artifacts
clean:
	rm -rf artifacts/ cache/ node_modules/

# Full setup
setup: install compile test

# Frontend setup
frontend-install:
	cd frontend && npm install --legacy-peer-deps

frontend-build:
	cd frontend && npm run build

frontend-start:
	cd frontend && npm start

# Documentation
docs-serve:
	cd docs && python -m http.server 8000
