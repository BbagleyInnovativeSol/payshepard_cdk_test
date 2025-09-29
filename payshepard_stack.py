from aws_cdk import (
    Stack,
    RemovalPolicy,
    CfnOutput,
    aws_s3 as s3,
    aws_s3tables as s3tables,
    aws_iam as iam,
    aws_quicksight as quicksight
)
from constructs import Construct

class PayShepardStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, external_account_id: str = "", **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        self.external_account_id = external_account_id
        
        # Create S3 Tables and buckets
        self.create_s3_tables_and_buckets()
        
        # Create IAM roles for cross-account access
        self.create_iam_roles()
        
        # Create QuickSight resources
        self.create_quicksight_resources()
        
        # Output important information
        self.create_outputs()

    def create_s3_tables_and_buckets(self):
        """Create S3 Tables for data storage and SPICE datasets"""
        
        # Create S3 Tables bucket (underlying storage for tables)
        self.data_bucket = s3.Bucket(
            self, "DataBucket",
            bucket_name=f"payshepard-data-{self.account}-{self.region}",
            versioned=True,
            encryption=s3.BucketEncryption.S3_MANAGED,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            removal_policy=RemovalPolicy.RETAIN
        )
        
        # Create S3 Tables namespace for organizing tables
        self.table_namespace = s3tables.CfnTableBucket(
            self, "TableBucket",
            name=f"payshepard-tables-{self.account}-{self.region}"
        )
        
        # Create S3 Tables bucket for client data
        self.client_data_bucket = s3tables.CfnTableBucket(
            self, "ClientDataBucket",
            name=f"payshepard-client-data-{self.account}-{self.region}"
        )

        # SPICE data bucket for QuickSight
        self.spice_bucket = s3.Bucket(
            self, "SpiceBucket",
            bucket_name=f"payshepard-spice-{self.account}-{self.region}",
            versioned=True,
            encryption=s3.BucketEncryption.S3_MANAGED,
            block_public_access=s3.BlockPublicAccess.BLOCK_ALL,
            removal_policy=RemovalPolicy.RETAIN
        )

    def create_iam_roles(self):
        """Create IAM roles for QuickSight and cross-account Glue access"""
        
        # QuickSight service role
        self.quicksight_role = iam.Role(
            self, "QuickSightServiceRole",
            assumed_by=iam.ServicePrincipal("quicksight.amazonaws.com"),
            role_name=f"PayShepard-QuickSight-Role-{self.region}",
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name("service-role/AWSQuickSightS3ConsumerReadOnlyAccess"),
                iam.ManagedPolicy.from_aws_managed_policy_name("AWSQuickSightAthenaAccess")
            ]
        )
        
        # Add inline policy for S3 bucket and S3 Tables access
        self.quicksight_role.add_to_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=[
                    "s3:GetObject",
                    "s3:ListBucket"
                ],
                resources=[
                    self.data_bucket.bucket_arn,
                    f"{self.data_bucket.bucket_arn}/*",
                    self.spice_bucket.bucket_arn,
                    f"{self.spice_bucket.bucket_arn}/*"
                ]
            )
        )
        
        # Add S3 Tables permissions for QuickSight
        self.quicksight_role.add_to_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=[
                    "s3tables:GetTable",
                    "s3tables:GetTableData",
                    "s3tables:ListTables"
                ],
                resources=[
                    f"arn:aws:s3tables:{self.region}:{self.account}:bucket/{self.table_namespace.name}/*",
                    f"arn:aws:s3tables:{self.region}:{self.account}:bucket/{self.client_data_bucket.name}/*"
                ]
            )
        )

        # Cross-account Glue access role (for future Glue job configuration)
        self.glue_access_role = iam.Role(
            self, "GlueCrossAccountRole",
            assumed_by=iam.ServicePrincipal("glue.amazonaws.com"),
            role_name=f"PayShepard-Glue-CrossAccount-{self.region}",
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name("service-role/AWSGlueServiceRole")
            ]
        )
        
        # Add cross-account Glue access policy
        cross_account_policy = iam.PolicyStatement(
            effect=iam.Effect.ALLOW,
            actions=[
                "glue:GetDatabase",
                "glue:GetDatabases",
                "glue:GetTable", 
                "glue:GetTables",
                "glue:GetPartition",
                "glue:GetPartitions",
                "glue:BatchGetPartition"
            ],
            resources=["*"]
        )
        
        if self.external_account_id:
            # Add specific external account resources if provided
            cross_account_policy.add_resources(
                f"arn:aws:glue:{self.region}:{self.external_account_id}:catalog",
                f"arn:aws:glue:{self.region}:{self.external_account_id}:database/*",
                f"arn:aws:glue:{self.region}:{self.external_account_id}:table/*/*/*"
            )
        
        self.glue_access_role.add_to_policy(cross_account_policy)
        
        # Add S3 access for data buckets and S3 Tables
        self.data_bucket.grant_read_write(self.glue_access_role)
        self.spice_bucket.grant_read_write(self.glue_access_role)
        
        # Add S3 Tables permissions
        self.glue_access_role.add_to_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=[
                    "s3tables:GetTable",
                    "s3tables:GetTableData",
                    "s3tables:PutTableData",
                    "s3tables:CreateTable",
                    "s3tables:UpdateTable",
                    "s3tables:ListTables"
                ],
                resources=[
                    f"arn:aws:s3tables:{self.region}:{self.account}:bucket/{self.table_namespace.name}/*",
                    f"arn:aws:s3tables:{self.region}:{self.account}:bucket/{self.client_data_bucket.name}/*"
                ]
            )
        )

    def create_quicksight_resources(self):
        """Create QuickSight data sources"""
        
        # Athena data source for connecting to Glue catalog
        self.athena_data_source = quicksight.CfnDataSource(
            self, "AthenaDataSource",
            aws_account_id=self.account,
            data_source_id="payshepard-athena-datasource",
            name="PayShepard Athena Data Source",
            type="ATHENA",
            data_source_parameters=quicksight.CfnDataSource.DataSourceParametersProperty(
                athena_parameters=quicksight.CfnDataSource.AthenaParametersProperty(
                    work_group="primary"
                )
            ),
            permissions=[
                quicksight.CfnDataSource.ResourcePermissionProperty(
                    principal=f"arn:aws:iam::{self.account}:root",
                    actions=[
                        "quicksight:DescribeDataSource",
                        "quicksight:DescribeDataSourcePermissions",
                        "quicksight:PassDataSource",
                        "quicksight:UpdateDataSource",
                        "quicksight:DeleteDataSource"
                    ]
                )
            ]
        )

        # S3 data source for direct S3 access
        self.s3_data_source = quicksight.CfnDataSource(
            self, "S3DataSource", 
            aws_account_id=self.account,
            data_source_id="payshepard-s3-datasource",
            name="PayShepard S3 Data Source",
            type="S3",
            permissions=[
                quicksight.CfnDataSource.ResourcePermissionProperty(
                    principal=f"arn:aws:iam::{self.account}:root",
                    actions=[
                        "quicksight:DescribeDataSource",
                        "quicksight:DescribeDataSourcePermissions", 
                        "quicksight:PassDataSource",
                        "quicksight:UpdateDataSource",
                        "quicksight:DeleteDataSource"
                    ]
                )
            ]
        )

    def create_outputs(self):
        """Create CloudFormation outputs"""
        
        CfnOutput(self, "DataBucketName",
                 value=self.data_bucket.bucket_name,
                 description="S3 bucket for data storage",
                 export_name="PayShepard-DataBucket")
        
        CfnOutput(self, "TableBucketName",
                 value=self.table_namespace.name,
                 description="S3 Tables namespace for structured data",
                 export_name="PayShepard-TableBucket")
        
        CfnOutput(self, "ClientDataBucketName",
                 value=self.client_data_bucket.name,
                 description="S3 Tables bucket for client data",
                 export_name="PayShepard-ClientDataBucket")
        
        CfnOutput(self, "SpiceBucketName", 
                 value=self.spice_bucket.bucket_name,
                 description="S3 bucket for SPICE datasets",
                 export_name="PayShepard-SpiceBucket")
        
        CfnOutput(self, "QuickSightRoleArn",
                 value=self.quicksight_role.role_arn,
                 description="QuickSight service role ARN",
                 export_name="PayShepard-QuickSightRole")
        
        CfnOutput(self, "GlueAccessRoleArn",
                 value=self.glue_access_role.role_arn,
                 description="Cross-account Glue access role ARN",
                 export_name="PayShepard-GlueAccessRole")
        
        CfnOutput(self, "AthenaDataSourceId",
                 value=self.athena_data_source.data_source_id,
                 description="QuickSight Athena data source ID",
                 export_name="PayShepard-AthenaDataSource")
        
        CfnOutput(self, "S3DataSourceId",
                 value=self.s3_data_source.data_source_id,
                 description="QuickSight S3 data source ID", 
                 export_name="PayShepard-S3DataSource")
        
        if self.external_account_id:
            CfnOutput(self, "ExternalAccountId",
                     value=self.external_account_id,
                     description="External account ID for cross-account access",
                     export_name="PayShepard-ExternalAccount")
