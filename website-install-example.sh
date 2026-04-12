#!/bin/bash
# ================================================================
# Nexus Installer — put this in your website repo
#
# Usage on your site (e.g., yourdomain.com/install):
#   curl -fsSL https://yourdomain.com/install.sh | bash
#
# This is just a thin redirect to the real install script
# in the public nexus repo. Keep this repo separate.
# ================================================================
set -e

exec bash <(curl -fsSL https://raw.githubusercontent.com/teohondascully/nexus/main/install.sh)
