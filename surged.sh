#!/bin/bash

# Exit on any error
set -e

echo "
 ____  _   _ ____   ____ _____ 
/ ___|| | | |  _ \ / ___| ____|
\___ \| | | | |_) | |  _|  _|  
 ___) | |_| |  _ <| |_| | |___ 
|____/ \___/|_| \_\\____|_____|
                               
=== Validator Setup Script ===
"
echo
echo "Please enter the following details for your validator setup:"
read -p "Enter node name: " NODE_NAME
read -p "Enter account name: " ACCOUNT_NAME
read -p "Enter validator moniker: " MONIKER
read -p "Enter website (optional, press enter to skip): " WEBSITE
read -p "Enter security contact email (optional, press enter to skip): " SECURITY_EMAIL
echo
echo
# Validate required inputs
if [ -z "$NODE_NAME" ] || [ -z "$ACCOUNT_NAME" ] || [ -z "$MONIKER" ]; then
    echo "Error: Node name, account name, and moniker are required!"
    exit 1
fi

echo "Using the following configuration:"
echo "Node Name: $NODE_NAME"
echo "Account Name: $ACCOUNT_NAME"
echo "Moniker: $MONIKER"
echo "Website: $WEBSITE"
echo "Security Email: $SECURITY_EMAIL"
echo
read -p "Is this correct? (y/n) " confirm
if [ "$confirm" != "y" ]; then
    echo "Setup cancelled. Please run the script again."
    exit 1
fi

echo "### Setting up the necessary packages ###"

# Detect OS and install dependencies
case "$(uname -s)" in
    Linux*)
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            echo "Installing dependencies for Debian/Ubuntu..."
            sudo apt-get update
            sudo apt-get install -y build-essential gcc pkg-config libssl-dev jq
        elif [ -f /etc/redhat-release ]; then
            # RHEL/CentOS/Fedora
            echo "Installing dependencies for RHEL/CentOS/Fedora..."
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y gcc pkg-config openssl-devel
        elif [ -f /etc/arch-release ]; then
            # Arch Linux
            echo "Installing dependencies for Arch Linux..."
            sudo pacman -S --noconfirm base-devel gcc pkg-config openssl
        else
            echo "Warning: Unsupported Linux distribution. Please install build-essential, gcc, pkg-config, and libssl-dev manually."
        fi
        ;;
    Darwin*)
        # macOS
        echo "Installing dependencies for macOS..."
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install gcc pkg-config openssl
        ;;
    MINGW*|CYGWIN*|MSYS*)
        # Windows
        echo "Installing dependencies for Windows..."
        if ! command -v choco &> /dev/null; then
            echo "Installing Chocolatey..."
            powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
        fi
        choco install -y mingw gcc-arm64 pkgconfiglite openssl
        ;;
    *)
        echo "Error: Unsupported operating system"
        exit 1
        ;;
esac

# Check if Go is already installed
if ! command -v go &> /dev/null || ! go version &> /dev/null; then
    echo "Installing Go..."
    curl -OL https://golang.org/dl/go1.23.1.linux-amd64.tar.gz
    sudo tar -C /usr/local -xvf go1.23.1.linux-amd64.tar.gz
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
    source ~/.profile
else
    echo "Go is already installed:"
    go version
fi

# Install Ignite CLI if not already installed
if ! command -v ignite &> /dev/null; then
    echo "Installing Ignite CLI..."
    curl https://get.ignite.com/cli! | bash
else
    echo "Ignite CLI is already installed:"
    ignite version
fi

echo "### Installing the chain's binary ###"
BINARY_URL="https://surge.sfo3.cdn.digitaloceanspaces.com/surged"
LIBWASM_URL="https://github.com/CosmWasm/wasmvm/releases/download/v2.1.2/libwasmvm.x86_64.so"

# Always install libwasmvm first
echo "Downloading and installing libwasmvm..."
curl -L $LIBWASM_URL -o libwasmvm.x86_64.so
sudo mv libwasmvm.x86_64.so /usr/lib/
sudo ldconfig

# Then handle the surged binary
if ! command -v surged &> /dev/null; then
    echo "Downloading surged binary..."
    curl -L $BINARY_URL -o surged
    chmod +x surged
    echo "Moving surged binary to /usr/local/bin..."
    sudo mv surged /usr/local/bin/
    
    # Verify the installation
    if ! command -v surged &> /dev/null; then
        echo "Error: Failed to install surged binary"
        exit 1
    fi
else
    echo "surged is already installed:"
    surged version
fi

# Initialize the node
echo "Initializing the node with name $NODE_NAME..."
if [ ! -f "$HOME/.surge/config/genesis.json" ]; then
    echo "Initializing the node with name $NODE_NAME..."
    surged init "$NODE_NAME" --chain-id surge
else
    echo "Node is already initialized."
fi
# Download and configure the genesis file
echo "Downloading genesis file..."

GENESIS_PATH="$HOME/.surge/config/genesis.json"
echo $GENESIS_PATH
if [ -f "$GENESIS_PATH" ]; then
    echo "Genesis file already exists, removing..."
    rm -f "$GENESIS_PATH"
fi
curl http://146.190.149.75:26657/genesis | jq '.result.genesis' > "$GENESIS_PATH"

# Update minimum-gas-prices in app.toml
APP_TOML="$HOME/.surge/config/app.toml"
echo "Updating minimum-gas-prices in app.toml..."
if grep -q "^minimum-gas-prices =" "$APP_TOML"; then
    sed -i 's|^minimum-gas-prices = .*|minimum-gas-prices = "0surg"|' "$APP_TOML"
else
    echo 'minimum-gas-prices = "0surg"' >> "$APP_TOML"
fi

# Update config.toml
echo "Configuring node settings in config.toml..."
CONFIG_FILE="$HOME/.surge/config/config.toml"
# Add or update persistent_peers
if grep -q "^persistent_peers =" "$CONFIG_FILE"; then
    sed -i 's|^persistent_peers =.*|persistent_peers = "4acf4e89422aa2eec9d27951fb5c9a512ed73362@146.190.149.75:26656"|' "$CONFIG_FILE"
else
    echo 'persistent_peers = "4acf4e89422aa2eec9d27951fb5c9a512ed73362@146.190.149.75:26656"' >> "$CONFIG_FILE"
fi
# Get the server's public IP address
echo "Fetching server's public IP address..."
SERVER_IP=$(curl -s https://api.ipify.org)
if [ -z "$SERVER_IP" ]; then
    echo "Warning: Could not fetch public IP address. Using fallback method..."
    SERVER_IP=$(curl -s http://checkip.amazonaws.com)
fi

if [ ! -z "$SERVER_IP" ]; then
    # Only update external_address if SERVER_IP was found
    if grep -q "^external_address =" "$CONFIG_FILE"; then
        sed -i "s|^external_address =.*|external_address = \"${SERVER_IP}:26656\"|" "$CONFIG_FILE"
    fi
else
    echo "Warning: Could not determine server's public IP address. Skipping external_address update."
fi

# Add or update RPC laddr
if grep -q "^laddr = \"tcp://127.0.0.1:26657\"" "$CONFIG_FILE"; then
    sed -i 's|^laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://0.0.0.0:26657"|' "$CONFIG_FILE"

fi

# Create systemd service file
echo "Creating systemd service file for surged..."
sudo tee /etc/systemd/system/surge-validator.service > /dev/null <<EOF
[Unit]
Description=Surge Node
After=network-online.target

[Service]
User=root
ExecStart=$(which surged) start
Restart=always
RestartSec=3
LimitNOFILE=65535
StandardOutput=append:/var/log/surge-validator.log
StandardError=append:/var/log/surge-validator-error.log

[Install]
WantedBy=multi-user.target
EOF

# Start the service
echo "Starting surge-validator service..."
sudo systemctl daemon-reload
sudo systemctl enable surge-validator
sudo systemctl start surge-validator

# Improved sync status checking
echo "Waiting for node to start and checking sync status..."
echo "This may take a few minutes..."

# Function to check if node is responding
check_node_status() {
    surged status 2>&1 | jq -r '.sync_info.catching_up + "|" + .sync_info.latest_block_height + "|" + .sync_info.earliest_block_height' 2>/dev/null
}

# Wait for node to start responding (max 60 seconds)
echo "Waiting for node to start..."
for i in {1..12}; do
    if surged status &>/dev/null; then
        echo "Node is responding!"
        break
    fi
    echo -n "."
    sleep 5
    if [ $i -eq 12 ]; then
        echo "Warning: Node is taking longer than expected to start. Check logs with: sudo journalctl -u surge-validator -f"
    fi
done

# Monitor sync progress
echo "Monitoring sync progress..."
while true; do
    STATUS=$(surged status 2>/dev/null)
    if [ $? -eq 0 ]; then
        CATCHING_UP=$(echo "$STATUS" | jq -r '.sync_info.catching_up')
        LATEST_HEIGHT=$(echo "$STATUS" | jq -r '.sync_info.latest_block_height')
        EARLIEST_HEIGHT=$(echo "$STATUS" | jq -r '.sync_info.earliest_block_height')
        LATEST_TIME=$(echo "$STATUS" | jq -r '.sync_info.latest_block_time')
        
        if [ "$CATCHING_UP" = "true" ]; then
            PROGRESS=$(echo "scale=2; ($EARLIEST_HEIGHT/$LATEST_HEIGHT) * 100" | bc)
            echo "Syncing... Block: $EARLIEST_HEIGHT / $LATEST_HEIGHT (${PROGRESS}%)"
            echo "Latest block time: $LATEST_TIME"
            sleep 10
        else
            echo "Node synced successfully at block height $LATEST_HEIGHT!"
            echo "Latest block time: $LATEST_TIME"
            break
        fi
    else
        echo "Waiting for node to respond..."
        sleep 5
    fi
done

echo "
==============================================
🎉 Node setup completed successfully! 🎉
==============================================
To check node status: surged status
To view logs: sudo journalctl -u surge-validator -f
==============================================
"