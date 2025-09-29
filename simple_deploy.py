#!/usr/bin/env python3
"""
Simple deployment script that handles AWS profiles with temporary credentials
"""
import boto3
import subprocess
import sys
import os

def deploy_with_profile(profile_name):
    """Deploy CDK using credentials from AWS profile"""
    
    print(f"🚀 Deploying PayShepard with profile: {profile_name}")
    
    try:
        # Create session with profile
        session = boto3.Session(profile_name=profile_name)
        
        # Test credentials work
        sts = session.client('sts')
        identity = sts.get_caller_identity()
        account_id = identity['Account']
        
        print(f"✅ Profile works for account: {account_id}")
        
        # Get credentials and set environment
        credentials = session.get_credentials()
        os.environ['AWS_ACCESS_KEY_ID'] = credentials.access_key
        os.environ['AWS_SECRET_ACCESS_KEY'] = credentials.secret_key
        if credentials.token:
            os.environ['AWS_SESSION_TOKEN'] = credentials.token
            
        # Set CDK environment
        os.environ['CDK_DEFAULT_ACCOUNT'] = account_id
        os.environ['CDK_DEFAULT_REGION'] = 'us-east-1'
        
        # Unset AWS_PROFILE to force use of environment variables
        if 'AWS_PROFILE' in os.environ:
            del os.environ['AWS_PROFILE']
            
        print("✅ Credentials configured for CDK")
        
        # Setup virtual environment
        print("📦 Setting up environment...")
        subprocess.run(['uv', 'sync'], check=True, capture_output=True)
        
        # Activate venv and deploy
        venv_python = '.venv/bin/python'
        venv_cdk = [venv_python, '-m', 'cdk']
        
        print("🔍 Testing CDK synthesis...")
        result = subprocess.run(venv_cdk + ['synth'], 
                              capture_output=True, text=True, env=os.environ)
        
        if result.returncode != 0:
            print(f"❌ CDK synthesis failed: {result.stderr}")
            return False
            
        print("✅ CDK synthesis successful")
        
        print("🚀 Deploying stack...")
        result = subprocess.run(venv_cdk + ['deploy', '--require-approval', 'never'], 
                              env=os.environ)
        
        if result.returncode == 0:
            print("🎉 Deployment completed successfully!")
            print(f"📊 Account: {account_id}")
            print("📋 Deployed Resources:")
            print("  ✓ S3 Tables namespaces (main + client data)")
            print("  ✓ S3 buckets (data + internal ETL)")
            print("  ✓ IAM roles (QuickSight + Glue)")
            print("  ✓ QuickSight data sources")
            return True
        else:
            print("❌ Deployment failed!")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python simple_deploy.py <profile-name>")
        print("Example: python simple_deploy.py innovative-sandbox")
        sys.exit(1)
        
    profile_name = sys.argv[1]
    success = deploy_with_profile(profile_name)
    sys.exit(0 if success else 1)
