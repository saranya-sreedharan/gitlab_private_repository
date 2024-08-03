
#!/bin/bash
# This script will create a private GitLab repository in your specific domain in Ubuntu 22.04

RED='\033[0;31m'  # Red colored text
NC='\033[0m'      # Normal text
YELLOW='\033[33m'  # Yellow Color
GREEN='\033[32m'   # Green Color
BLUE='\033[34m'    # Blue Color

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root.${NC}"
    exit 1
fi


echo "Enter the Domain_name:"
read -r domain_name

# Ask the user for the email address
echo -e "${YELLOW}Enter your email address for Let's Encrypt certificate:${NC}"
read -r email_address

echo -e "${YELLOW}Enter the port number for GitLab (e.g., 8080):${NC}"
read -r gitlab_port


# Create 'gitlab' user and group
echo -e "${YELLOW}... Creating 'gitlab' user and group...${NC}"
if ! sudo useradd -m -U gitlab; then
    echo -e "${RED}... Failed to create 'gitlab' user and group${NC}"
    exit 1
else
    echo -e "${GREEN}... 'gitlab' user and group created successfully${NC}"
fi

# Set password for 'gitlab' user
echo -e "${YELLOW}... Setting password for 'gitlab' user...${NC}"
if ! sudo passwd gitlab; then
    echo -e "${RED}... Failed to set password for 'gitlab' user${NC}"
    exit 1
else
    echo -e "${GREEN}... Password set for 'gitlab' user${NC}"
fi

# Switch to 'gitlab' user
echo -e "${YELLOW}... Switching to user 'gitlab'...${NC}"
if ! sudo su - gitlab <<'EOF'
    # Inside the 'gitlab' user context
    echo "You are now in the 'gitlab' user context."
EOF
then
    echo -e "${RED}... Failed to switch to 'gitlab' user context${NC}"
    exit 1
fi

echo -e "${YELLOW}... Updating packages${NC}"
# Update package information
if ! sudo apt update; then
    echo -e "${RED}The system update failed.${NC}"
    exit 1
fi



# Installing GitLab repo registry
echo -e "${YELLOW}... Installing the GitLab repo registry...${NC}"
if ! curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash; then
    echo -e "${RED}... Failed to install GitLab repo${NC}"
    exit 1
else 
    echo -e "${GREEN}... GitLab Repo registry successfully installed${NC}"
fi
sleep 10
# Installing GitLab 
echo -e "${YELLOW}... Installing GitLab...${NC}"
if ! sudo apt install gitlab-ce; then 
    echo -e "${RED}... Failed to install GitLab${NC}"
    exit 1
else
    echo -e "${GREEN}... GitLab successfully installed${NC}"
fi

sleep 10
# Configuring GitLab with custom domain
echo -e "${YELLOW}... Configuring GitLab with domain name${NC}"
if ! sudo sed -i "s|^external_url .*|external_url 'http://$domain_name:$gitlab_port'|g" /etc/gitlab/gitlab.rb ; then 
    echo -e "${RED}... Failed to update custom domain...${NC}"
    exit 1
else 
    echo -e "${GREEN}... Successfully updated with custom domain${NC}"
fi
sleep 10
# We’ll run the following command to force GitLab to reconfigure (This will take some time) - for understanding
echo -e "${YELLOW}... Updating GitLab with modified configuration${NC}"
if ! sudo gitlab-ctl reconfigure; then
    echo -e "${RED}... Failed to configure GitLab after modification with user domain name${NC}"
    exit 1
else 
    echo -e "${GREEN}... Successfully configured GitLab with custom domain${NC}"
fi

# Password will be automatically generated. So we need to take the password, it should be in the following file
#password=$(sudo cat /etc/gitlab/initial_root_password)

# Display the password in blue color
#echo -e "${YELLOW}... Initial root password: ${BLUE}$password${NC}"

# Check if the site is reachable
#response=$(curl -IsS --max-time 5 "http://$domain_name" | head -n 1)

#if [[ "$response" == *"200 OK"* ]]; then
#    echo -e "${GREEN}Website is reachable.${NC}"
#else
 #   echo -e "${RED}Website is not reachable or returned a non-OK status.${NC}"
#fi

#echo -e "${GREEN}Script executed successfully reachable to custom domain.${NC}"


# Command 1: Update external_url
echo -e "${YELLOW}... Updating external_url in GitLab configuration${NC}"
if sudo sed -i "s|^external_url .*|external_url 'https://$domain_name:$gitlab_port'|g" /etc/gitlab/gitlab.rb; then
    echo -e "${GREEN}... external_url updated successfully${NC}"
else
    echo -e "${RED}... Failed to update external_url${NC}"
    exit 1
fi

# Command 2: Uncomment and set letsencrypt['enable'] to true
echo -e "${YELLOW}... Updating letsencrypt configuration in GitLab${NC}"
if sudo sed -i 's/^# *\(letsencrypt\['\''enable'\''\].*\)/\1/g; s/\(^letsencrypt\['\''enable'\''\].*\)/letsencrypt['\''enable'\''] = true/g' /etc/gitlab/gitlab.rb; then
    echo -e "${GREEN}... letsencrypt configuration updated successfully${NC}"
else
    echo -e "${RED}... Failed to update letsencrypt configuration${NC}"
    exit 1
fi

# Command 3: Uncomment letsencrypt['contact_emails']
echo -e "${YELLOW}... Uncommenting letsencrypt['contact_emails'] in GitLab configuration${NC}"
if sudo sed -i 's/^# *\(letsencrypt\['"'"'contact_emails'"'"'\].*\)/\1/g' /etc/gitlab/gitlab.rb; then
    echo -e "${GREEN}... letsencrypt['contact_emails'] uncommented successfully${NC}"
else
    echo -e "${RED}... Failed to uncomment letsencrypt['contact_emails']${NC}"
    exit 1
fi

# Command 4: Set custom email for letsencrypt['contact_emails']
echo -e "${YELLOW}... Setting custom email for letsencrypt['contact_emails'] in GitLab configuration${NC}"
if sudo sed -i "s|letsencrypt\['contact_emails'\].*|letsencrypt['contact_emails'] = ['$email_address']|g" /etc/gitlab/gitlab.rb; then
    echo -e "${GREEN}... Custom email set for letsencrypt['contact_emails'] successfully${NC}"
else
    echo -e "${RED}... Failed to set custom email for letsencrypt['contact_emails']${NC}"
    exit 1
fi

# Command 5: Uncomment letsencrypt['auto_renew']
echo -e "${YELLOW}... Uncommenting letsencrypt['auto_renew'] in GitLab configuration${NC}"
if sudo sed -i 's/^# *\(letsencrypt\['"'"'auto_renew'"'"'\].*\)/\1/g' /etc/gitlab/gitlab.rb; then
    echo -e "${GREEN}... letsencrypt['auto_renew'] uncommented successfully${NC}"
else
    echo -e "${RED}... Failed to uncomment letsencrypt['auto_renew']${NC}"
    exit 1
fi

echo -e "${GREEN}... GitLab configuration updated successfully${NC}"


# Run GitLab reconfiguration
echo -e "${YELLOW}... Updating GitLab with SSL certificate...${NC}"
if ! sudo gitlab-ctl reconfigure; then 
    echo -e "${RED}... Failed to configure GitLab with SSL certificate${NC}"
    exit 1 
else
    echo -e "${GREEN}... Successfully updated GitLab with SSL certificate${NC}"
fi

echo -e "${GREEN}... The GitLab repository is created successfully...${NC}"

echo -e "${BLUE}.....The initial password is '/etc/gitlab/initial_root_password' file sudo cat to see the password. Usernaame will be 'root'${NC}"