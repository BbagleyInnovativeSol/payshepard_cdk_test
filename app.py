#!/usr/bin/env python3
import os
import aws_cdk as cdk
from payshepard_stack import PayShepardStack

app = cdk.App()

# Get environment configuration
env = cdk.Environment(
    account=os.getenv('CDK_DEFAULT_ACCOUNT'),
    region=os.getenv('CDK_DEFAULT_REGION', 'us-east-1')
)

# External account configuration for cross-account Glue access
external_account_id = app.node.try_get_context("external_account_id")
if not external_account_id:
    print("WARNING: external_account_id not provided in context.")
    print("Set with: cdk deploy --context external_account_id=123456789012")
    external_account_id = ""

# Create the main stack
payshepard_stack = PayShepardStack(
    app, "PayShepardStack",
    external_account_id=external_account_id,
    env=env
)

# Add tags
cdk.Tags.of(payshepard_stack).add("Project", "PayShepard")
cdk.Tags.of(payshepard_stack).add("Environment", "production")

app.synth()
