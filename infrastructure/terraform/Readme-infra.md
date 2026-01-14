### infrastructure/terraform

- where to run terraform from folder -> /env
- what modules exist ?
- required AWS permissions ?
- outputs you depend on later (for Helm)

### Checklist

- “Terraform is executed from environments/dev”
- module list + what each creates
- how to destroy safely


### Setup/execution plan : 

- Run from:
- .../infra/terraform/environments/dev

### Checklist (execute in order):

```
 terraform init
 terraform fmt -recursive
 terraform validate
 terraform plan
 terraform apply
```

### cluster access + gpu readiness

- aws eks update-kubeconfig --region <region> --name <cluster_name>
- kubectl get nodes
- confirm the GPU taint/labels:
-  kubectl get nodes --show-labels | grep accelerator
- kubectl describe node <gpu-node> | grep -i taints -A2
