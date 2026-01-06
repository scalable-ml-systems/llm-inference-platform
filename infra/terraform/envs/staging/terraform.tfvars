region       = "us-east-1"
profile      = "default"
env          = "staging"
project_name = "vllm-platform"

github_org  = "your-org"
github_repo = "your-org/your-repo"

# Fill after cluster creation
oidc_provider_arn = "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/<CLUSTER_ID>"
oidc_provider_url = "oidc.eks.us-east-1.amazonaws.com/id/<CLUSTER_ID>"
