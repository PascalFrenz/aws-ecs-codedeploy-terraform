# Setting up the Infrastructure

1. Clone this repository
2. Copy `./config/example.tfvars` to `./config/<env>.tfvars` (replace <env> with the name of the environment you want to deploy to) and edit the variables so they match your environment
3. Copy `./config/example.s3.tfbackend` to `./config/<env>.s3.tfbackend` (replace <env> with the name of the environment you want to deploy to) and edit the variables so they match your environment
    * Alternatively, configure your backend how you like in the [backend.tf](backend.tf) file
4. Run `terraform init -backend-config=./config/<env>.s3.tfbackend`
5. Create a plan with `terraform plan -var-file=./<env>.tfvars -out=plan.tfplan`
6. If you are happy with the plan, apply it with `terraform apply plan.tfplan`


# Destroying the Infrastructure

1. Run `terrafrom plan -var-file=./<env>.tfvars -out=plan.tfplan -destroy`
2. Review the output of the command and confirm that you want to destroy the infrastructure
3. Run `terraform apply plan.tfplan` to destroy the infrastructure
4. Finally, remove the `plan.tfplan` file
