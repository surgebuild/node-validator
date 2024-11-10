# surge-validator

A guide to setting up and operating a validator node on the Surge Metalayer network.

## Overview

To become a validator on the Surge Metalayer, you'll need to complete several steps:

- Setting up the necessary hardware and software
- Installing the chain's binary
- Syncing node with the network
- Creating a validator account
- Staking tokens and becoming an active validator

## Quick Installation

Install Surge using the following command:

```bash
curl -L https://install.surge.dev/validator_script.sh | bash
```

This script will:
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

### Creating a Validator Account

> **Note:** Skip this section if you're only operating a node, not a validator node.

Create a new account:

```bash
surged keys add <enter-the-account-name-you-want>
```

This will generate:
- A new account address
- A mnemonic phrase

⚠️ **Important:** Safely store your mnemonic phrase - it's required to recover your account.

### Configuring Validator Details

1. Create a validator configuration file:

```bash
nano ~/.surge/config/validator.json
```

2. Add the following configuration (replace with your details):

```json
{
  "pubkey": {
    "@type": "/cosmos.crypto.ed25519.PubKey",
    "key": "your node public key"
  },
  "amount": "100000000srg",
  "moniker": "your node name",
  "identity": "",
  "website": "http://your-validator-website.com",
  "security": "contact@your-validator.com",
  "details": "A description of your validator",
  "commission-rate": "0.05",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
```

### Creating the Validator

Submit the create-validator transaction:

```bash
surged tx staking create-validator /root/.surge/config/validator.json \
  --from <your account name> \
  --chain-id surge \
  --fees 70srg \
  --gas auto \
  --gas-adjustment 1.4 \
  --home ~/.surge \
  --node http://localhost:26657
```

Upon successful submission, you'll receive a transaction hash. Example response:

```bash
code: 0
codespace: ""
data: ""
events: []
gas_used: "0"
gas_wanted: "0"
height: "0"
info: ""
logs: []
raw_log: '[]'
timestamp: ""
tx: null
txhash: 3068ED7C9867D9DC926A200363704715AE9470EE73452324A32C2583E62B1D79
```

### Verifying Validator Status

To confirm your validator has been accepted into the active set, query the validator set using the `surged` command (specific command to be provided by the network).

## Support

For additional support or questions, please visit our [GitHub repository](https://github.com/surgebuild/surge-validator) or join our community channels.