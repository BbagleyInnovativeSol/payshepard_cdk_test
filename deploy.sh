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

# Check if AWS CLI is configured and get account info
echo -e "${BLUE}Validating AWS credentials and getting account info...${NC}"
ACCOUNT_INFO=$(aws sts get-caller-identity --profile $PROFILE_NAME 2>/dev/null)
if [ $? -ne 0 ]; then
    echo -e "${RED}AWS CLI not configured or no valid credentials found for profile: $PROFILE_NAME${NC}"
    echo -e "${YELLOW}If this profile requires MFA, use: python simple_deploy.py $PROFILE_NAME${NC}"
    echo "Please configure the profile or get MFA session first"
    exit 1
fi

# Extract account ID from the response
ACCOUNT_ID=$(echo "$ACCOUNT_INFO" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
AWS_REGION=$(aws configure get region --profile $PROFILE_NAME || echo "us-east-1")

echo -e "${GREEN}✓ AWS credentials validated${NC}"
echo -e "${GREEN}✓ Account ID: ${ACCOUNT_ID}${NC}"
echo -e "${GREEN}✓ Region: ${AWS_REGION}${NC}"

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


# Create S3 Tables buckets first
aws s3tables create-table-bucket --name payshepard_internal --region us-east-1
aws s3tables create-table-bucket --name client_a --region us-east-1

# Deploy
cdk deploy

# Create s3 buckets




#
# # Extract credentials from profile for CDK
# echo -e "\n${BLUE}Extracting credentials for CDK...${NC}"
# if python extract_profile_creds.py $PROFILE_NAME; then
#     echo -e "${GREEN}✓ Credentials extracted successfully${NC}"
#     # Unset AWS_PROFILE since we're using explicit credentials
#     unset AWS_PROFILE
# else
#     echo -e "${RED}Failed to extract credentials from profile${NC}"
#     exit 1
# fi
#
# # Set CDK environment variables
# export CDK_DEFAULT_ACCOUNT=$ACCOUNT_ID
# export CDK_DEFAULT_REGION=$AWS_REGION
#
# echo -e "${GREEN}✓ CDK environment configured${NC}"
#
# # Check if our stack uses bootstrap resources (it doesn't for S3, IAM, QuickSight only)
# echo -e "\n${BLUE}Checking bootstrap requirements...${NC}"
# # Our stack only uses S3, IAM, and QuickSight - no bootstrap required
# echo "Stack uses only S3, IAM, and QuickSight resources - skipping bootstrap"
#
# # Deploy stack (within virtual environment)
# echo -e "\n${BLUE}Deploying PayShepard stack...${NC}"
# # Deploy using extracted credentials (no profile needed)
# cdk deploy --require-approval never
#
# echo -e "\n${GREEN}Deployment completed successfully!${NC}"
# echo -e "\n${BLUE}Deployed Resources:${NC}"
# echo "✓ S3 Tables namespace for structured data"
# echo "✓ S3 Tables bucket for client data"
# echo "✓ S3 bucket for data storage"
# echo "✓ S3 bucket for internal data ETL and processing"
# echo "✓ IAM roles for QuickSight and cross-account Glue access with S3 Tables support"
# echo "✓ QuickSight data sources (Athena and S3)"
#
# echo -e "\n${BLUE}Next Steps:${NC}"
# echo "1. Configure QuickSight permissions in AWS Console"
# echo "2. Set up external account resource policies (see README)"
# echo "3. Create tables in the S3 Tables namespaces (main and client data)"
# echo "4. Create Glue jobs or use existing ones from external account"
# echo "5. Create QuickSight datasets and analyses"
#
# echo -e "\n${BLUE}Useful Commands:${NC}"
# echo "- View stack outputs: aws cloudformation describe-stacks --stack-name PayShepardStack --profile $PROFILE_NAME"
# echo "- Access QuickSight: https://quicksight.aws.amazon.com/"
# echo "- CDK commands: source .venv/bin/activate && export AWS_PROFILE=$PROFILE_NAME CDK_DEFAULT_ACCOUNT=$ACCOUNT_ID CDK_DEFAULT_REGION=$AWS_REGION && cdk <command>"
# echo "- Account ID: $ACCOUNT_ID"
# echo "- Region: $AWS_REGION"
