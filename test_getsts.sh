#!/bin/bash

# aws configure
PROFILE=$1
export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity --profile $PROFILE --query Account --output text)
export CDK_DEFAULT_REGION=us-east-1

# Python package management
uv sync
source .venv/bin/activate
$(echo which python3)

# echo -e "Info = $CDK_DEFAULT_ACCOUNT/$CDK_DEFAULT_REGION"
cdk bootstrap $CDK_DEFAULT_ACCOUNT/$CDK_DEFAULT_REGION --profile $PROFILE --tags Creator=bbagley@innovativesol.com

# cdk synth
# missing s3tables:CreateTableBucket policy
# aws s3tables create-table-bucket --name bbagley-s3table-dev --region us-east-1 --profile $PROFILE
