#!/bin/bash

# Validation script for PayShepard CDK deployment
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}PayShepard Deployment Validation${NC}"
echo -e "${BLUE}=================================${NC}"

# Test 1: Check UV is installed
echo -e "\n${BLUE}1. Checking UV installation...${NC}"
if command -v uv &> /dev/null; then
    UV_VERSION=$(uv --version)
    echo -e "${GREEN}✓ UV is installed: ${UV_VERSION}${NC}"
else
    echo -e "${RED}✗ UV not found${NC}"
    exit 1
fi

# Test 2: Check CDK is installed  
echo -e "\n${BLUE}2. Checking CDK installation...${NC}"
if command -v cdk &> /dev/null; then
    CDK_VERSION=$(cdk --version)
    echo -e "${GREEN}✓ CDK is installed: ${CDK_VERSION}${NC}"
else
    echo -e "${RED}✗ CDK not found${NC}"
    exit 1
fi

# Test 3: Virtual environment setup
echo -e "\n${BLUE}3. Testing virtual environment setup...${NC}"
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    uv venv
fi

echo -e "${GREEN}✓ Virtual environment exists${NC}"

# Test 4: Dependency installation
echo -e "\n${BLUE}4. Testing dependency installation...${NC}"
uv sync > /dev/null 2>&1
echo -e "${GREEN}✓ Dependencies installed successfully${NC}"

# Test 5: Python imports
echo -e "\n${BLUE}5. Testing Python imports...${NC}"
source .venv/bin/activate
python -c "import aws_cdk; print('✓ aws_cdk imported')"
python -c "import constructs; print('✓ constructs imported')"
python -c "import aws_cdk.aws_s3tables as s3tables; print('✓ s3tables imported')"
echo -e "${GREEN}✓ All imports successful${NC}"

# Test 6: CDK synthesis
echo -e "\n${BLUE}6. Testing CDK synthesis...${NC}"
if cdk synth > /dev/null 2>&1; then
    echo -e "${GREEN}✓ CDK synthesis successful${NC}"
else
    echo -e "${RED}✗ CDK synthesis failed${NC}"
    exit 1
fi

# Test 7: Stack validation
echo -e "\n${BLUE}7. Validating stack resources...${NC}"
SYNTH_OUTPUT=$(cdk synth)

# Check for required resources
if echo "$SYNTH_OUTPUT" | grep -q "AWS::S3Tables::TableBucket"; then
    echo -e "${GREEN}✓ S3 Tables resources found${NC}"
else
    echo -e "${RED}✗ S3 Tables resources missing${NC}"
    exit 1
fi

if echo "$SYNTH_OUTPUT" | grep -q "AWS::S3::Bucket"; then
    echo -e "${GREEN}✓ S3 Bucket resources found${NC}"
else
    echo -e "${RED}✗ S3 Bucket resources missing${NC}"
    exit 1
fi

if echo "$SYNTH_OUTPUT" | grep -q "AWS::IAM::Role"; then
    echo -e "${GREEN}✓ IAM Role resources found${NC}"
else
    echo -e "${RED}✗ IAM Role resources missing${NC}"
    exit 1
fi

if echo "$SYNTH_OUTPUT" | grep -q "AWS::QuickSight::DataSource"; then
    echo -e "${GREEN}✓ QuickSight DataSource resources found${NC}"
else
    echo -e "${RED}✗ QuickSight DataSource resources missing${NC}"
    exit 1
fi

# Test 8: Project structure
echo -e "\n${BLUE}8. Validating project structure...${NC}"
REQUIRED_FILES=("app.py" "payshepard_stack.py" "pyproject.toml" "requirements.txt" "cdk.json" "deploy.sh")

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ ${file} exists${NC}"
    else
        echo -e "${RED}✗ ${file} missing${NC}"
        exit 1
    fi
done

echo -e "\n${GREEN}🎉 All validation tests passed!${NC}"
echo -e "\n${BLUE}Ready for deployment. Usage:${NC}"
echo -e "${YELLOW}./deploy.sh your-profile-name${NC}"

echo -e "\n${BLUE}Stack Summary:${NC}"
echo "• 2 S3 Tables buckets (main tables + client data)"
echo "• 2 S3 buckets (data storage + SPICE datasets)" 
echo "• IAM roles for QuickSight and cross-account Glue access"
echo "• QuickSight data sources (Athena + S3)"
echo "• Full S3 Tables permissions for both QuickSight and Glue"
