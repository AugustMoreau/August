#!/bin/bash

# Text colors for output messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if curl is installed, and install it if not
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}Installing curl...${NC}"
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Check if bc is installed, and install it if not
echo -e "${BLUE}Checking your OS version...${NC}"
if ! command -v bc &> /dev/null; then
    echo -e "${YELLOW}Installing bc...${NC}"
    sudo apt update
    sudo apt install bc -y
fi
sleep 1

# Check the version of Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${RED}A minimum version of Ubuntu 22.04 is required for this node${NC}"
    exit 1
fi

# Menu for selecting actions
echo -e "${YELLOW}Select an action:${NC}"
echo -e "${CYAN}1) Install the node${NC}"
echo -e "${CYAN}2) Check logs${NC}"
echo -e "${CYAN}3) Update the node${NC}"
echo -e "${CYAN}4) Restart the node${NC}"
echo -e "${CYAN}5) Remove the node${NC}"

echo -e "${YELLOW}Enter a number:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Installing the BlockMesh node...${NC}"

        # Check if tar is installed, and install it if not
        if ! command -v tar &> /dev/null; then
            echo -e "${YELLOW}Installing tar...${NC}"
            sudo apt install tar -y
        fi
        sleep 1

        # Download the BlockMesh binary
        wget https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.358/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to download BlockMesh binary. Check your internet connection.${NC}"
            exit 1
        fi

        # Extract the archive
        tar -xzvf blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to extract BlockMesh binary. Check the archive file.${NC}"
            exit 1
        fi
        sleep 1

        # Remove the archive
        rm blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Navigate to the folder
        cd target/x86_64-unknown-linux-gnu/release/ || { echo -e "${RED}Directory not found. Check the extracted files.${NC}"; exit 1; }

        # Make the binary executable
        chmod +x blockmesh-cli

        # Request user input
        echo -e "${YELLOW}Enter your email for BlockMesh:${NC} "
        read EMAIL
        echo -e "${YELLOW}Enter your password for BlockMesh:${NC} "
        read PASSWORD

        # Determine the current user's name and home directory
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Create or update the service file
        sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli login --email $EMAIL --password $PASSWORD
WorkingDirectory=$HOME_DIR/target/x86_64-unknown-linux-gnu/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Reload services and enable BlockMesh
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable blockmesh
        sudo systemctl start blockmesh

        # Final message
        echo -e "${GREEN}Installation completed and the node is running!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Command to check logs:${NC}" 
        echo "sudo journalctl -u blockmesh -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2

        # Check logs
        sudo journalctl -u blockmesh -f
        ;;

    2)
        # Check logs
        sudo journalctl -u blockmesh -f
        ;;

    3)
        echo -e "${BLUE}Updating the BlockMesh node...${NC}"

        # Stop the service
        sudo systemctl stop blockmesh
        sudo systemctl disable blockmesh
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        sleep 1

        # Remove old node files
        rm -rf target
        sleep 1

        # Download the new BlockMesh binary
        wget https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.339/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to download BlockMesh binary. Check your internet connection.${NC}"
            exit 1
        fi

        # Extract the archive
        tar -xzvf blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to extract BlockMesh binary. Check the archive file.${NC}"
            exit 1
        fi
        sleep 1

        # Remove the archive
        rm blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

        # Navigate to the folder
        cd target/x86_64-unknown-linux-gnu/release/ || { echo -e "${RED}Directory not found. Check the extracted files.${NC}"; exit 1; }

        # Make the binary executable
        chmod +x blockmesh-cli

        # Request user input to update variables
        echo -e "${YELLOW}Enter your email for BlockMesh:${NC} "
        read EMAIL
        echo -e "${YELLOW}Enter your password for BlockMesh:${NC} "
        read PASSWORD

        # Create or update the service file
        sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli login --email $EMAIL --password $PASSWORD
WorkingDirectory=$HOME_DIR/target/x86_64-unknown-linux-gnu/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Reload services
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable blockmesh
        sudo systemctl restart blockmesh

        # Final message
        echo -e "${GREEN}Update completed and the node is running!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Command to check logs:${NC}" 
        echo "sudo journalctl -u blockmesh -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2

        # Check logs
        sudo journalctl -u blockmesh -f
        ;;

    4)
        echo -e "${BLUE}Restarting the BlockMesh node...${NC}"

        # Stop the service
        sudo systemctl stop blockmesh

        # Navigate to the folder
        cd target/x86_64-unknown-linux-gnu/release/ || { echo -e "${RED}Directory not found. Check the folder path.${NC}"; exit 1; }

        # Make the binary executable
        chmod +x blockmesh-cli

        # Request user input
        echo -e "${YELLOW}Enter your email for BlockMesh:${NC} "
        read EMAIL
        echo -e "${YELLOW}Enter your password for BlockMesh:${NC} "
        read PASSWORD

        # Create or update the service file
        sudo bash -c "cat <<EOT > /etc/systemd/system/blockmesh.service
[Unit]
Description=BlockMesh CLI Service
After=network.target

[Service]
User=$USERNAME
ExecStart=$HOME_DIR/target/x86_64-unknown-linux-gnu/release/blockmesh-cli login --email $EMAIL --password $PASSWORD
WorkingDirectory=$HOME_DIR/target/x86_64-unknown-linux-gnu/release
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        # Reload services
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl restart blockmesh

        # Final message
        echo -e "${GREEN}Restart completed and the node is running with new data!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Command to check logs:${NC}" 
        echo "sudo journalctl -u blockmesh -f"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2

        # Check logs
        sudo journalctl -u blockmesh -f
        ;;

    5)
        echo -e "${BLUE}Removing the BlockMesh node...${NC}"

        # Stop and disable the service
        sudo systemctl stop blockmesh
        sudo systemctl disable blockmesh
        sudo rm /etc/systemd/system/blockmesh.service
        sudo systemctl daemon-reload
        sleep 1

        # Remove the target folder with files
        rm -rf target

        echo -e "${GREEN}The BlockMesh node has been successfully removed!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 1
        ;;
esac
