# AWS ECS Deployment with CodeDeploy

This repository contains an example of how to configure an AWS ECS Service to be deployed using CodeDeploy in Terraform.

## Prerequisites

* Access to AWS Account via AWS CLI
* Terraform

## Usage

1. Clone this repository
2. Copy `./config/example.tfvars` to `./config/<env>.tfvars` (replace <env> with the name of the environment you want to deploy to) and edit the variables so they match your environment
3. Copy `./config/example.s3.tfbackend` to `./config/<env>.s3.tfbackend` (replace <env> with the name of the environment you want to deploy to) and edit the variables so they match your environment
    * Alternatively, configure your backend how you like in the [backend.tf](./backend.tf) file
4. Run `terraform init -backend-config=./config/<env>.s3.tfbackend`
5. Create a plan with `terraform plan -var-file=./<env>.tfvars -out=plan.tfplan`
6. If you are happy with the plan, apply it with `terraform apply plan.tfplan`

Now you can deploy the created ECS Service using CodeDeploy via the AWS Console or the AWS CLI.

## Reference Resources

* [AWS CodeDeploy with ECS](https://docs.aws.amazon.com/codedeploy/latest/userguide/tutorial-ecs-deployment.html)

