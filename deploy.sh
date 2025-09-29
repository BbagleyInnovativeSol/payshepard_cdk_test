#!/bin/bash

# PayShepard Simple Deployment Script
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}PayShepard Simple Deployment${NC}"
echo -e "${BLUE}============================${NC}"

# Check if external account ID is provided
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: ./deploy.sh <PROFILE_NAME>${NC}"
    echo -e "${YELLOW}Example: ./deploy.sh profile-abc${NC}"
    exit 1
fi

PROFILE_NAME="$1"
echo -e "${GREEN}Profile Name: ${PROFILE_NAME}${NC}"

# EXTERNAL_ACCOUNT="$1"
# echo -e "${GREEN}External Account ID: ${EXTERNAL_ACCOUNT}${NC}"

# Check prerequisites
echo -e "\n${BLUE}Checking prerequisites...${NC}"

# Check if UV is installed
if ! command -v uv &> /dev/null; then
    echo -e "${RED}UV not found. Please install it first:${NC}"
    echo "curl -LsSf https://astral.sh/uv/install.sh | sh"
    echo "or: pip install uv"
    exit 1
fi

# Check if CDK is installed
if ! command -v cdk &> /dev/null; then
    echo -e "${RED}CDK CLI not found. Please install it first:${NC}"
    echo "npm install -g aws-cdk"
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity --profile $1 &> /dev/null; then
    echo -e "${RED}AWS CLI not configured or no valid credentials found${NC}"
    echo "Please run 'aws configure' first"
    exit 1
fi

echo -e "${GREEN}Prerequisites check passed!${NC}"

# Create and setup virtual environment with UV
echo -e "\n${BLUE}Setting up virtual environment with UV...${NC}"
if [ ! -d ".venv" ]; then
    uv venv
fi

# Install Python dependencies using UV
echo -e "\n${BLUE}Installing Python dependencies with UV...${NC}"
if [ -f "pyproject.toml" ]; then
    uv sync
else
    uv pip install -r requirements.txt
fi

# Activate virtual environment
echo -e "\n${BLUE}Activating virtual environment...${NC}"
source .venv/bin/activate

# Bootstrap CDK if needed (within virtual environment)
echo -e "\n${BLUE}Bootstrapping CDK environment...${NC}"
cdk bootstrap

# Deploy stack (within virtual environment)
echo -e "\n${BLUE}Deploying PayShepard stack...${NC}"
# cdk deploy --context external_account_id=$EXTERNAL_ACCOUNT --require-approval never
cdk deploy --context profile=$PROFILE_NAME --require-approval never

echo -e "\n${GREEN}Deployment completed successfully!${NC}"
echo -e "\n${BLUE}Deployed Resources:${NC}"
echo "✓ S3 Tables namespace for structured data"
echo "✓ S3 Tables bucket for client data"
echo "✓ S3 bucket for data storage"
echo "✓ S3 bucket for SPICE datasets"
echo "✓ IAM roles for QuickSight and cross-account Glue access with S3 Tables support"
echo "✓ QuickSight data sources (Athena and S3)"

echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. Configure QuickSight permissions in AWS Console"
echo "2. Set up external account resource policies (see README)"
echo "3. Create tables in the S3 Tables namespaces (main and client data)"
echo "4. Create Glue jobs or use existing ones from external account"
echo "5. Create QuickSight datasets and analyses"

echo -e "\n${BLUE}Useful Commands:${NC}"
echo "- View stack outputs: aws cloudformation describe-stacks --stack-name PayShepardStack --profile $PROFILE_NAME"
echo "- Access QuickSight: https://quicksight.aws.amazon.com/"
echo "- CDK commands: source .venv/bin/activate && cdk <command>"
