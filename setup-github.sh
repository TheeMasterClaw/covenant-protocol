#!/bin/bash
# Setup script for GitHub repository

echo "🚀 COVENANT Protocol - GitHub Setup"
echo "===================================="

# Check if git is initialized
if [ ! -d .git ]; then
    echo "Initializing git repository..."
    git init
fi

# Add all files
echo "Adding files to git..."
git add .

# Initial commit
echo "Creating initial commit..."
git commit -m "Initial commit: COVENANT Protocol v1.0

- 6 smart contracts (1,903 lines Solidity)
- AgentRegistry for agent discovery
- CovenantFactory for agreement creation
- TaskMarket for decentralized tasks
- ReputationStake for on-chain reputation
- DisputeDAO for arbitration
- Full React frontend
- 18 passing tests
- Hardhat deployment configured for X Layer"

# Instructions for adding remote
echo ""
echo "===================================="
echo "Next steps:"
echo "1. Create a new repository on GitHub"
echo "2. Run: git remote add origin https://github.com/YOUR_USERNAME/covenant-protocol.git"
echo "3. Run: git branch -M main"
echo "4. Run: git push -u origin main"
echo ""
echo "For Vercel deployment:"
echo "1. Go to https://vercel.com/new"
echo "2. Import your GitHub repo"
echo "3. Set root directory to 'frontend'"
echo "4. Add environment variables from .env file"
echo "===================================="
