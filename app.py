#!/usr/bin/env python3
import os
import aws_cdk as cdk
from s3_bucket_tables.s3_buckettable_stack import PayShepardS3Stack

app = cdk.App()

# Define AWS environment
aws_env = cdk.Environment(
    account=os.environ.get('CDK_DEFAULT_ACCOUNT'),
    region=os.environ.get('CDK_DEFAULT_REGION', 'us-east-1')
)

PayShepardS3Stack(
    app,
    "PayshepardStack",
    description="Test Description"
)
