RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No color (reset)


if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1


echo -e "${YELLOW}Select an action:${NC}"
echo -e "${CYAN}1) Install node${NC}"
echo -e "${CYAN}2) Check node status${NC}"
echo -e "${CYAN}3) Remove node${NC}"

echo -e "${YELLOW}Enter the number:${NC} "
read choice

case $choice in
    1)
        echo -e "${BLUE}Installing the node...${NC}"

    
        sudo apt update && sudo apt upgrade -y

       
        echo -e "${BLUE}Checking system architecture...${NC}"
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
        elif [[ "$ARCH" == "aarch64" ]]; then
            CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
        else
            echo -e "${RED}Unsupported system architecture: $ARCH${NC}"
            exit 1
        fi

    
        echo -e "${BLUE}Downloading client from $CLIENT_URL...${NC}"
        wget $CLIENT_URL -O multipleforlinux.tar

       
        echo -e "${BLUE}Extracting files...${NC}"
        tar -xvf multipleforlinux.tar

     
        cd multipleforlinux

 
        echo -e "${BLUE}Setting permissions...${NC}"
        chmod +x ./multiple-cli
        chmod +x ./multiple-node

       
        echo -e "${BLUE}Adding directory to system PATH...${NC}"
        echo "PATH=\$PATH:$(pwd)" >> ~/.bash_profile
        source ~/.bash_profile

     
        echo -e "${BLUE}Starting multiple-node...${NC}"
        nohup ./multiple-node > output.log 2>&1 &

      
        echo -e "${YELLOW}Enter your Account ID:${NC}"
        read IDENTIFIER
        echo -e "${YELLOW}Set your PIN:${NC}"
        read PIN

     
        echo -e "${BLUE}Binding account with ID: $IDENTIFIER and PIN: $PIN...${NC}"
        ./multiple-cli bind --bandwidth-download 100 --identifier $IDENTIFIER --pin $PIN --storage 200 --bandwidth-upload 100

    
        echo -e "${GREEN}Installation completed successfully!${NC}"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        echo -e "${YELLOW}Command to check node status:${NC}"
        echo "cd ~/multipleforlinux && ./multiple-cli status"
        echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
        sleep 2
        cd ~/multipleforlinux && ./multiple-cli status
        ;;

    2)
      
        echo -e "${BLUE}Checking status...${NC}"
        cd ~/multipleforlinux && ./multiple-cli status
        ;;

    3)
        echo -e "${BLUE}Removing node...${NC}"

      
        pkill -f multiple-node

       
        cd ~
        rm -rf multipleforlinux

        echo -e "${GREEN}Node removed successfully!${NC}"
        sleep 1
        ;;
        
    *)
        echo -e "${RED}Invalid choice. Please enter a number from 1 to 3.${NC}"
        ;;
esac
