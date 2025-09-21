#!/usr/bin/env bash
if [ "$#" -eq 0 ] || [[ " $@ " =~ " --help " ]]; then

YELLOW='\033[1;33m'
NC='\033[0m'
echo -e "${YELLOW}
█▀ █▀▀ █▀▀ █▀█ █▀▀ ▀█▀ █▀   █▀▀ █   █
▄█ ██▄ █▄▄ █▀▄ ██▄  █  ▄█   █▄▄ █▄▄ █
${NC}"

fi
