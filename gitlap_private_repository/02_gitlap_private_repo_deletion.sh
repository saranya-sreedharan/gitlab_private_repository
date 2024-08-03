#!/bin/bash
# This script will completely remove GitLab and its configurations

RED='\033[0;31m'  # Red colored text
NC='\033[0m'      # Normal text
YELLOW='\033[33m'  # Yellow Color
GREEN='\033[32m'   # Green Color

# Stop GitLab services
echo -e "${YELLOW}... Stopping GitLab services...${NC}"
if ! sudo gitlab-ctl stop; then
 echo -e "${RED}... Failed to Stope GitLab services...${NC}"
 exit 1
fi  

# Uninstall GitLab
echo -e "${YELLOW}... Uninstalling GitLab...${NC}"
if ! sudo apt-get purge -y gitlab-ce; then
 echo -e "${RED}... Failed to remove GitLab services...${NC}"
 exit 1
fi

# Remove GitLab configurations and data
echo -e "${YELLOW}... Removing GitLab configurations and data...${NC}"
if ! sudo rm -rf /etc/gitlab /var/opt/gitlab /var/log/gitlab;then
  echo -e "${RED}... Removing GitLab configurations and data...${NC}"
  exit 1
fi

if ! sudo rm -rf /opt/gitlab; then
 echo -e "${RED}... Failed to Remove GitLab configurations and data from /opt/gitlab...${NC}"
 exit 1
fi

if ! sudo rm -rf /run/gitlab; then
 echo -e "${RED}... Failed to Remove GitLab configurations and data from /run/gitlab...${NC}"
 exit 1
fi

if ! sudo rm -rf /etc/gitlab; then
 echo -e "${RED}... Failed to Remove GitLab configurations and data from /etc/gitlab...${NC}"
 exit 1
fi
# Remove GitLab user 
echo -e "${YELLOW}... Removing GitLab user and group...${NC}"
if ! sudo deluser gitlab; then
 echo -e "${RED}... Failed to Remove gitlab user...${NC}"
 exit 1
fi
sudo delgroup gitlab

# Remove GitLab dependencies
echo -e "${YELLOW}... Removing GitLab dependencies...${NC}"
if ! sudo apt-get autoremove -y; then
 echo -e "${RED}... autoclean command failed...${NC}"
 exit 1
fi

if ! sudo apt-get clean; then
 echo -e "${RED}... Clean command failed...${NC}"
 exit 1
fi 

# Remove GitLab logs
echo -e "${YELLOW}... Removing GitLab logs...${NC}"
if ! sudo rm -rf /var/log/gitlab/* /var/log/gitlab/.gitlab_shell_upgrade; then
  echo -e "${RED}... Clean command failed...${NC}"
  exit 1
fi

# Remove GitLab runit services
echo -e "${YELLOW}... Removing GitLab runit services...${NC}"
if ! sudo rm -rf /opt/gitlab/sv/*; then
 echo -e "${RED}... runit clean command failed...${NC}"
 exit 1
fi 
# Remove GitLab service data
echo -e "${YELLOW}... Removing GitLab service data...${NC}"
if ! sudo rm -rf /opt/gitlab/service/*; then
 echo -e "${RED}... clean service command failed...${NC}"
 exit 1
fi 

# Check this completely uninstalled.
echo -e "${YELLOW}... Checking for remaining GitLab files...${NC}"

if sudo find / -type f -name "gitlab*" -exec rm -f {} \; 2>/dev/null; then
  echo -e "${GREEN}... Remaining GitLab files removed.${NC}"
else
  echo -e "${RED}... Failed to remove remaining GitLab files or no files found.${NC}"
fi


echo -e "${GREEN}... GitLab completely uninstalled.${NC}"

