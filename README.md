# AWS ECS Deployment with CodeDeploy
![Static Badge](https://img.shields.io/badge/status-actively%20maintained-3ea218?logo=gitlab)
![GitLab Issues](https://img.shields.io/gitlab/issues/open/57710266?logo=gitlab)
![GitLab Merge Requests](https://img.shields.io/gitlab/merge-requests/open/57710266?logo=gitlab)

This repository contains an example of how to configure an AWS ECS Service to be deployed using CodeDeploy in Terraform.

## Prerequisites

* Access to AWS Account via AWS CLI
* Terraform

## Usage

Set up the infrastructure with Terraform as described here: [Infrastructure Setup](./infrastructure/README.md#setting-up-the-infrastructure)

Now you can deploy the created ECS Service using CodeDeploy via the AWS Console or the AWS CLI.
To do this you will need an AppSpec file that describes the deployment.
Here is an example of such a file:

```yaml
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "arn:aws:ecs:us-east-1:111222333444:task-definition/my-task-definition-family-name:1"
        LoadBalancerInfo:
          ContainerName: "webserver"
          ContainerPort: 8080
```

Once you are done testing, you can destroy the infrastructure with Terraform to prevent incurring more cost.
See here for how to do that: [Infrastructure Destruction](./infrastructure/README.md#destroying-the-infrastructure).

## Reference Resources

* [AWS CodeDeploy with ECS](https://docs.aws.amazon.com/codedeploy/latest/userguide/tutorial-ecs-deployment.html)
* [AppSpec file Examples](https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-example.html)
