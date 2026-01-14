region       = "us-east-1"
profile      = "default"
env          = "dev"
project_name = "vllm-platform"

github_org  = "your-org"
github_repo = "your-org/your-repo"

# Variables - update after cluster creation
oidc_provider_arn = "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/oidc.eks.<region>.amazonaws.com/id/<CLUSTER_ID>"
oidc_provider_url = "oidc.eks.<region>.amazonaws.com/id/<CLUSTER_ID>"
