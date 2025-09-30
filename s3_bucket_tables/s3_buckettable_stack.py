from aws_cdk import(
    Stack,
        aws_s3 as s3,
        CfnOutput,
    RemovalPolicy
    )

from constructs import Construct

class PayShepardS3Stack(Stack):
    def __init__(self, scope: Construct, construction_id:str, **kwargs) -> None:
        """Initialize the S3 buckets, S3 Tables"""

        super().__init__(scope, construction_id, **kwargs)

        #s3 buckets creation
        self.create_s3_buckets()

        
    def create_s3_buckets(self):
        """Create S3 buckets for Athena queries, client data, and internal use"""
        
        # Athena queries
        self.athena_bucket = s3.Bucket(
            self,
            "AthenaBucket",
            bucket_name="payshepard_athena",
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True 
        )
        
        # # Silver bucket (processed Parquet data)
        # self.silver_bucket = s3.Bucket(
        #     self,
        #     "SilverBucket",
        #     bucket_name=f"integrity-partners-silver-{self.env_name}",
        #     removal_policy=RemovalPolicy.DESTROY if self.env_name != "prod" else RemovalPolicy.RETAIN,
        #     auto_delete_objects=True if self.env_name != "prod" else False
        # ) 
    CfnOutput(self,
              "create_s3_buckets",
              value=self.create_s3_buckets,
              description = "Created bucket"
              )
