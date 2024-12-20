# Surge Validator Node Setup Guide

A guide to setting up and operating a validator node on the Surge Metalayer network.

## Overview

To become a validator on the Surge Metalayer, you'll need to complete several steps:

- Setting up the necessary hardware and software
- Installing the chain's binary
- Syncing node with the network
- Creating a validator account
- Staking tokens and becoming an active validator

### Hardware Requirements
- CPU: 4+ cores (recommended)
- RAM: 4GB minimum, 8GB recommended
- Storage: 250GB minimum SSD/NVMe (recommended for future growth)
- Network: Stable internet connection with 10Mbps+ bandwidth

## Installation Options

### Option 1: Remote Installation (Recommended)

Install Surge using the following command:

```bash
curl -L https://install.surge.dev/surged.sh | bash
```

### Option 2: Local Installation

1. Clone the repository:
```bash
git clone https://github.com/surgebuild/node-validator
cd node-validator
```

2. Make the script executable and run:
```bash
./surged.sh
```

The installation script will:
- Install all required software
- Configure the node
- Begin syncing with the network

### Checking Sync Status

Monitor your node's synchronization progress:

```bash
surged status
```

Look for the `catching_up` field in the output - when it shows `false`, your node has fully synchronized with the network.

## Validator Setup

### 1. Create Validator Account
```bash
surged keys add <validator-account-name>
```

⚠️ **Important:** Safely store the generated mnemonic phrase - it's required for account recovery.

### 2. Configure Validator
Create and edit the validator configuration:

```bash
# Create config directory if it doesn't exist
mkdir -p ~/.surge/config

# Create and edit validator config
cat > ~/.surge/config/validator.json << 'EOF'
{
  "pubkey": {
    "@type": "/cosmos.crypto.ed25519.PubKey",
    "key": "<your-node-public-key>"
  },
  "amount": "100000000surg",
  "moniker": "<your-validator-name>",
  "identity": "",
  "website": "https://your-website.com",
  "security": "security@your-validator.com",
  "details": "Description of your validator",
  "commission-rate": "0.05",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF
```

### 3. Create Validator
```bash
surged tx staking create-validator ~/.surge/config/validator.json \
  --from <validator-account-name> \
  --chain-id surge-alphatestnet-1 \
  --fees 70surg \
  --gas auto \
  --gas-adjustment 1.4 \
  --home ~/.surge \
  --node http://localhost:26657
```

### 4. Verify Status
Check if your validator is in the active set:
```bash
surged query staking validator $(surged keys show <validator-account-name> --bech val -a)
```

## Managing the Service

After installing the Surge validator using the bash script, you can manage the system service with the following commands:

### Checking Logs

To view the logs for the Surge validator, use the following command:

```bash
# View the main log file
tail -f /var/log/surge-validator.log

# View the error log file
tail -f /var/log/surge-validator-error.log
```

### Restarting the Service

To restart the Surge validator service, run:

```bash
sudo systemctl restart surge-validator
```

### Stopping the Service

To stop the Surge validator service, use:

```bash
sudo systemctl stop surge-validator
```

### Starting the Service

If you need to start the service after stopping it, use:

```bash
sudo systemctl start surge-validator
```

### Checking Service Status

To check the status of the Surge validator service, you can run:

```bash
sudo systemctl status surge-validator
```

## Support

For additional support or questions, please visit our [GitHub repository](https://github.com/surgebuild/surge-validator) or join our community channels.
