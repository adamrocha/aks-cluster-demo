SHELL := /bin/bash
S3_BUCKET=terraform-state-bucket-2727
DYNAMO_TABLE=terraform-locks
TF_DIR=terraform


tf-format:
	cd $(TF_DIR) && terraform fmt
	@echo "✅ Terraform files formatted."

tf-init:
	cd $(TF_DIR) && terraform init
	@echo "✅ Terraform initialized."

tf-validate:
	cd $(TF_DIR) && terraform validate
	@echo "✅ Terraform configuration validated."

tf-plan:
	cd $(TF_DIR) && terraform plan
	@echo "✅ Terraform plan completed."

tf-apply:
	cd $(TF_DIR) && terraform apply
	@echo "✅ Terraform resources deployed."

tf-destroy:
	cd $(TF_DIR) && terraform destroy
	@echo "✅ Terraform resources destroyed."

tf-output:
	cd $(TF_DIR) && terraform output
	@echo "✅ Terraform outputs displayed."
	@echo "🔍 To view specific output, run 'terraform output <output_name>'."

tf-state:
	cd $(TF_DIR) && terraform state list
	@echo "✅ Terraform state listed."
	@echo "🔍 To view specific resource, run 'terraform state show <resource_name>'."