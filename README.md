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
- **S3 Buckets**: SPICE dataset storage and data processing
- **IAM Roles**: Cross-account Glue access and QuickSight permissions with S3 Tables support
- **QuickSight Data Sources**: Athena and S3 connections
- **Cross-Account Setup**: Ready for external Glue catalog integration

## Quick Start

### Prerequisites

- AWS CLI configured with appropriate credentials
- AWS CDK CLI installed: `npm install -g aws-cdk`
- Python 3.9+
- QuickSight subscription in your AWS account
- External account ID with Glue catalog access

### Deploy

```bash
./deploy.sh 123456789012  # Replace with your external account ID
```

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
- `SpiceBucketName`: S3 bucket for SPICE datasets
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
├── requirements.txt          # Python dependencies
├── cdk.json                 # CDK configuration  
├── deploy.sh               # Simple deployment script
└── README.md              # This file
```

## Key Features

✅ **Minimal complexity** - Single stack deployment  
✅ **Cross-account ready** - IAM roles and policies configured  
✅ **QuickSight integration** - Data sources pre-configured  
✅ **S3 optimization** - Lifecycle policies for cost savings  
✅ **Secure by default** - Proper encryption and access controls  

## Support

This is a simplified deployment focused on service setup. For Glue job configuration and data pipeline implementation, refer to AWS Glue documentation or extend this stack as needed.
