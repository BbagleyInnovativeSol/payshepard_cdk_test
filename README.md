# PayShepard - Simple QuickSight with Cross-Account Glue

A simplified AWS CDK project that deploys the essential services for QuickSight integration with external account Glue catalogs.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  External       │    │  Current Account │    │  Amazon         │
│  Account        │    │                  │    │  QuickSight     │
│                 │    │  ┌─────────────┐ │    │                 │
│  ┌────────────┐ │    │  │ IAM Roles   │ │    │  ┌────────────┐ │
│  │ Glue       │◄┼────┼─►│ for Cross   │ │    │  │ Data       │ │
│  │ Catalog    │ │    │  │ Account     │ │    │  │ Sources    │ │
│  └────────────┘ │    │  └─────────────┘ │    │  │ - Athena   │ │
│                 │    │          │       │    │  │ - S3       │ │
└─────────────────┘    │          ▼       │    │  └────────────┘ │
                       │  ┌─────────────┐ │    │        ▲        │
                       │  │ S3 Buckets  │ │    │        │        │
                       │  │ - Data      │◄┼────┼────────┘        │
                       │  │ - SPICE     │ │    │                 │
                       │  └─────────────┘ │    │                 │
                       └──────────────────┘    └─────────────────┘
```

## What's Deployed

- **S3 Tables**: 
  - Main tables namespace for structured data storage
  - Client data bucket for client-specific tables
- **S3 Buckets**: Data processing and internal ETL operations
- **IAM Roles**: Cross-account Glue access and QuickSight permissions with S3 Tables support
- **QuickSight Data Sources**: Athena and S3 connections
- **Cross-Account Setup**: Ready for external Glue catalog integration

## Quick Start

### Prerequisites

- **UV** installed: `curl -LsSf https://astral.sh/uv/install.sh | sh` (or `pip install uv`)
- **AWS CLI** configured with appropriate credentials and profiles
- **AWS CDK CLI** installed: `npm install -g aws-cdk`
- **Python 3.9+**
- **QuickSight subscription** in your AWS account
- **External account ID** with Glue catalog access (optional)

### Validate Setup

Before deploying, validate your environment:

```bash
./validate_deployment.sh
```

This will test:
- UV and CDK installations
- Virtual environment setup
- Dependency installation
- Python imports
- CDK synthesis
- Stack resource validation

### Deploy

```bash
./deploy.sh profile-name  # Replace with your AWS CLI profile name
```

The script will:
- Check for UV and other prerequisites
- Validate AWS credentials and extract account information
- Create and activate a virtual environment using UV
- Install dependencies with UV (faster than pip)
- Bootstrap and deploy the CDK stack using the specified profile

## External Account Configuration

To enable cross-account access, configure the following in your **external account**:

### 1. Glue Resource Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR-CURRENT-ACCOUNT:role/PayShepard-Glue-CrossAccount-REGION"
      },
      "Action": [
        "glue:GetDatabase",
        "glue:GetTable", 
        "glue:GetPartitions"
      ],
      "Resource": [
        "arn:aws:glue:REGION:EXTERNAL-ACCOUNT:catalog",
        "arn:aws:glue:REGION:EXTERNAL-ACCOUNT:database/*",
        "arn:aws:glue:REGION:EXTERNAL-ACCOUNT:table/*/*/*"
      ]
    }
  ]
}
```

### 2. S3 Bucket Policy (if applicable)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR-CURRENT-ACCOUNT:role/PayShepard-Glue-CrossAccount-REGION"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::external-data-bucket/*",
        "arn:aws:s3:::external-data-bucket"
      ]
    }
  ]
}
```

## Post-Deployment Steps

### 1. Configure QuickSight Permissions

1. Go to AWS QuickSight Console
2. Navigate to Manage QuickSight → Security & permissions  
3. Add S3 access to your deployed buckets
4. Enable Athena access

### 2. Create Glue Jobs (Optional)

The stack provides the foundation. You can now:
- Create Glue jobs that read from external account
- Use the cross-account IAM role provided
- Store processed data in the deployed S3 buckets

### 3. Create QuickSight Datasets

Use the deployed data sources to create:
- SPICE datasets for fast performance
- Direct query datasets for real-time data
- Custom analyses and dashboards

## Stack Outputs

After deployment, the stack provides:

- `DataBucketName`: S3 bucket for processed data  
- `TableBucketName`: S3 Tables namespace for structured data
- `ClientDataBucketName`: S3 Tables bucket for client data
- `InternalDataEtlBucketName`: S3 bucket for internal data ETL and processing
- `QuickSightRoleArn`: IAM role for QuickSight with S3 Tables permissions
- `GlueAccessRoleArn`: IAM role for cross-account Glue access with S3 Tables support
- `AthenaDataSourceId`: QuickSight Athena data source
- `S3DataSourceId`: QuickSight S3 data source

## View Stack Outputs

```bash
aws cloudformation describe-stacks --stack-name PayShepardStack --query "Stacks[0].Outputs"
```

## Clean Up

To remove all resources:

```bash
cdk destroy
```

**Note**: S3 buckets are retained by default to prevent data loss.

## Project Structure

```
payshepard_cdk_test/
├── app.py                    # Main CDK application
├── payshepard_stack.py       # Single stack with all resources
├── requirements.txt          # Python dependencies (legacy)
├── pyproject.toml           # Modern Python project config (UV)
├── cdk.json                 # CDK configuration  
├── deploy.sh               # UV-based deployment script
├── validate_deployment.sh   # Pre-deployment validation script
└── README.md              # This file
```

## Key Features

✅ **Minimal complexity** - Single stack deployment  
✅ **Cross-account ready** - IAM roles and policies configured  
✅ **QuickSight integration** - Data sources pre-configured  
✅ **Internal ETL operations** - Dedicated bucket for data processing workflows  
✅ **Secure by default** - Proper encryption and access controls  

## UV Benefits

- **Faster installs**: 10-100x faster than pip  
- **Better dependency resolution**: More reliable conflict resolution
- **Virtual environment management**: Automatic venv creation and management
- **Lock file support**: Reproducible installations with `uv.lock`
- **Modern tooling**: Built in Rust for performance

## Development Commands

```bash
# Activate virtual environment
source .venv/bin/activate

# Install dependencies with UV
uv sync  # if using pyproject.toml
# or
uv pip install -r requirements.txt  # if using requirements.txt

# CDK commands (in virtual environment with profile and account info)
export AWS_PROFILE=your-profile
export CDK_DEFAULT_ACCOUNT=123456789012  # Your account ID
export CDK_DEFAULT_REGION=us-east-1      # Your region
cdk list
cdk diff
cdk synth
cdk deploy

# Check stack status
aws cloudformation describe-stacks --stack-name PayShepardStack --profile your-profile
```

## Support

This is a simplified deployment focused on service setup. For Glue job configuration and data pipeline implementation, refer to AWS Glue documentation or extend this stack as needed.
