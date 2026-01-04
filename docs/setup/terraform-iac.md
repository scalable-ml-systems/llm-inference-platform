# Terraform for Infra as code 
===================================

### ROOT TERRAFORM FILES

infra/
  terraform/
    provider.tf          # AWS provider configuration (region, profile)
    versions.tf          # Terraform + provider version constraints
    backend.tf           # Remote state backend (S3 + DynamoDB)
    variables.tf         # Global variables shared across modules
    outputs.tf           # Global outputs (cluster name, VPC ID, etc.)
    main.tf              # Root module wiring (calls all submodules)
    terraform.tfvars     # Environment-specific values (dev/prod)


### CORE MODULES

modules/
  vpc/                  
    main.tf             # VPC, subnets, NAT, routing
    variables.tf        # Inputs: CIDRs, AZs, env
    outputs.tf          # Outputs: VPC ID, subnet IDs

  security/
    main.tf             # Security groups for nodes, FSx, observability
    variables.tf        # Inputs: VPC ID, env
    outputs.tf          # Outputs: SG IDs

  iam/
    main.tf             # IAM roles: cluster, nodes, IRSA roles
    variables.tf        # Inputs: env, OIDC provider
    outputs.tf          # Outputs: IAM role ARNs
    policies/           
      s3_read.json          # vLLM model bucket read-only policy
      fsx_access.json       # FSx CSI driver permissions
      autoscaler.json       # Cluster Autoscaler permissions
      ecr_push.json         # CI/CD push to ECR
      s3_artifacts.json     # CI/CD artifact bucket access

  eks/
    main.tf             # EKS cluster + GPU node groups
    variables.tf        # Inputs: IAM roles, subnets, env
    outputs.tf          # Outputs: cluster name, OIDC, endpoint

  storage/
    main.tf             # S3 model bucket + FSx Lustre filesystem
    variables.tf        # Inputs: VPC, subnets, env
    outputs.tf          # Outputs: bucket name, FSx DNS

  ecr/
    main.tf             # ECR repositories for vLLM + router images
    variables.tf        # Inputs: env
    outputs.tf          # Outputs: repo URLs

  kms/
    main.tf             # KMS keys for S3, FSx, logs, ECR
    variables.tf        # Inputs: env
    outputs.tf          # Outputs: KMS key ARNs

  cicd/
    main.tf             # GitHub OIDC provider + CI/CD IAM role
    variables.tf        # Inputs: repo name, env
    outputs.tf          # Outputs: CI/CD role ARN
    policies/
      github_oidc.json      # Trust policy for GitHub Actions
      ecr_push.json         # ECR push permissions
      s3_artifacts.json     # Artifact bucket permissions


### observability, scaling, and cost‑efficiency

  observability/
    main.tf             # Prometheus, Grafana, Loki, DCGM exporter (via Helm)
    variables.tf        # Inputs: cluster name, namespace, env
    outputs.tf          # Outputs: dashboard URLs, workspace IDs
    dashboards/
      vllm-metrics.json     # Custom vLLM latency + tokens/sec dashboard
      gpu-utilization.json  # GPU memory/utilization dashboard
      cost-tracking.json    # GPU-hour + cost-per-1k-tokens dashboard

  autoscaling/
    main.tf             # HPA, Karpenter, GPU bin-packing, IRSA for autoscaler
    variables.tf        # Inputs: cluster name, env
    outputs.tf          # Outputs: autoscaling status
    policies/
      gpu-scaling.json       # GPU-aware scaling policy
      queue-based-scaling.json # Queue-length scaling policy (future router)

  cost-management/
    main.tf             # Cost & usage reports, Athena queries, tagging
    variables.tf        # Inputs: env
    outputs.tf          # Outputs: cost dashboards, CUR bucket

### networking, routing, and secrets hygiene.

  networking/
    main.tf             # ALB ingress, NLB, service mesh (optional)
    variables.tf        # Inputs: VPC, subnets, env
    outputs.tf          # Outputs: ALB DNS, mesh endpoints
    components/
      alb-controller.tf # AWS Load Balancer Controller
      istio.tf          # Optional: Istio gateway for multi-model routing

  secrets/
    main.tf             # Secrets Manager + SSM Parameter Store
    variables.tf        # Inputs: env
    outputs.tf          # Outputs: secret ARNs



### DISASTER RECOVERY AND TESTING

  disaster-recovery/
    main.tf             # Backups, cross-region replication, FSx snapshots
    variables.tf        # Inputs: env
    outputs.tf          # Outputs: DR status

  testing/
    main.tf             # Infra validation, smoke tests, conformance tests
    variables.tf        # Inputs: env
    outputs.tf          # Outputs: test results
    tests/
      test_vpc.tf       # Example: VPC validation test
      test_eks.tf       # Example: EKS health test


### ENVIRONMENTS

envs/
  dev/
    main.tf             # Dev wiring of modules
    variables.tf        # Dev-specific variables
    terraform.tfvars    # Dev values (small GPU nodes)

  prod/
    main.tf             # Prod wiring of modules
    variables.tf        # Prod-specific variables
    terraform.tfvars    # Prod values (P4/P5 nodes, FSx enabled)

  staging/
    main.tf             # Staging for router A/B testing
    variables.tf        # Staging-specific variables
    terraform.tfvars    # Staging values
