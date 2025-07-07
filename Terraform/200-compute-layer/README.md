# Create the lambda_packages directory
mkdir -p 200-compute-layer/lambda_packages

# Initialize and deploy London
terraform init -backend-config=backend-config.hcl
terraform workspace new london
terraform plan -var-file=vars/london.tfvars
terraform apply -var-file=vars/london.tfvars

# Deploy Sydney
terraform workspace new sydney
terraform plan -var-file=vars/sydney.tfvars
terraform apply -var-file=vars/sydney.tfvars