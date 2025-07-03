# ToDo Manager - AWS ECS Deployment Guide (FIXED)

## 🔧 Issue Fixed

**Problem**: The original deployment script had a critical flaw where the CloudFormation template tried to deploy an ECS service that referenced a Docker image that didn't exist yet in ECR.

**Solution**: Split the deployment into two phases:
1. **Infrastructure Phase**: Deploy VPC, ECR, CodeCommit, ALB, and ECS cluster
2. **Application Phase**: Build and push Docker image, then deploy ECS service

## 📁 Fixed Files

- `infrastructure-template.yaml` - Infrastructure-only CloudFormation template
- `ecs-service-template.yaml` - ECS service CloudFormation template  
- `deploy-fixed.sh` - Fixed deployment script with correct order
- `check-deployment-fixed.sh` - Updated status checker for new stack structure

## 🚀 Quick Deployment (Fixed)

### Option 1: Full Automated Deployment

```bash
# Use the fixed deployment script
./deploy-fixed.sh
```

This script now follows the correct order:
1. ✅ Deploy infrastructure (VPC, ECR, ALB, etc.)
2. ✅ Build Spring Boot application
3. ✅ Build and push Docker image to ECR
4. ✅ Deploy ECS service (now that image exists)
5. ✅ Set up CodeCommit repository

### Option 2: Step-by-Step Deployment

#### Step 1: Deploy Infrastructure Only

```bash
aws cloudformation deploy \
    --template-file infrastructure-template.yaml \
    --stack-name todo-manager-dev-infra \
    --parameter-overrides \
        ApplicationName=todo-manager \
        Environment=dev \
    --capabilities CAPABILITY_NAMED_IAM \
    --region us-east-1
```

#### Step 2: Build and Push Application

```bash
# Build application
./mvnw clean package -DskipTests

# Get ECR URI from infrastructure stack
ECR_URI=$(aws cloudformation describe-stacks \
    --stack-name todo-manager-dev-infra \
    --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryURI`].OutputValue' \
    --output text)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

# Build and push Docker image
docker build -t todo-manager:latest .
docker tag todo-manager:latest $ECR_URI:latest
docker push $ECR_URI:latest
```

#### Step 3: Deploy ECS Service

```bash
aws cloudformation deploy \
    --template-file ecs-service-template.yaml \
    --stack-name todo-manager-dev-service \
    --parameter-overrides \
        ApplicationName=todo-manager \
        Environment=dev \
        ImageTag=latest \
    --region us-east-1
```

## 🔄 Update Existing Deployment

To update your application after making code changes:

```bash
# Quick update (skips infrastructure)
./deploy-fixed.sh --update-only
```

Or manually:
```bash
# Build new version
./mvnw clean package -DskipTests

# Build and push new image
docker build -t todo-manager:latest .
docker tag todo-manager:latest $ECR_URI:latest
docker push $ECR_URI:latest

# Update ECS service
aws cloudformation deploy \
    --template-file ecs-service-template.yaml \
    --stack-name todo-manager-dev-service \
    --parameter-overrides \
        ApplicationName=todo-manager \
        Environment=dev \
        ImageTag=latest
```

## 📊 Check Deployment Status

Use the fixed status checker:

```bash
./check-deployment-fixed.sh
```

This will check:
- ✅ Infrastructure stack status
- ✅ Service stack status  
- ✅ ECS service health
- ✅ ALB target health
- ✅ Application endpoints
- ✅ Recent logs

## 🏗️ Architecture Overview

### Two-Stack Approach

**Infrastructure Stack** (`todo-manager-dev-infra`):
- VPC with public/private subnets
- NAT Gateway and Internet Gateway
- ECR Repository
- CodeCommit Repository
- Application Load Balancer
- ECS Cluster
- Security Groups
- IAM Roles
- CloudWatch Log Groups

**Service Stack** (`todo-manager-dev-service`):
- ECS Task Definition
- ECS Service
- References infrastructure via CloudFormation exports

### Benefits of This Approach

1. **Correct Deployment Order**: Infrastructure is created before trying to deploy containers
2. **Separation of Concerns**: Infrastructure and application lifecycle are separate
3. **Faster Updates**: Can update application without touching infrastructure
4. **Better Error Handling**: Clear separation makes troubleshooting easier
5. **Cost Efficiency**: Can tear down service stack while keeping infrastructure

## 🛠️ Troubleshooting

### Common Issues and Solutions

1. **ECS Service Fails to Start**
   ```bash
   # Check if image exists in ECR
   aws ecr describe-images --repository-name todo-manager-dev
   
   # Check ECS service events
   aws ecs describe-services --cluster todo-manager-dev-cluster --services todo-manager-dev-service
   ```

2. **Health Check Failures**
   ```bash
   # Check application logs
   aws logs tail /ecs/todo-manager-dev --follow
   
   # Test health endpoint directly
   curl http://your-alb-url/actuator/health
   ```

3. **Stack Deployment Failures**
   ```bash
   # Check CloudFormation events
   aws cloudformation describe-stack-events --stack-name todo-manager-dev-infra
   aws cloudformation describe-stack-events --stack-name todo-manager-dev-service
   ```

### Deployment Order Issues

If you encounter issues related to deployment order:

1. **Infrastructure First**: Always deploy infrastructure stack first
2. **Image Availability**: Ensure Docker image is pushed to ECR before deploying service
3. **Stack Dependencies**: Service stack depends on infrastructure stack exports

## 🧹 Cleanup

To remove all resources:

```bash
# Delete service stack first
aws cloudformation delete-stack --stack-name todo-manager-dev-service
aws cloudformation wait stack-delete-complete --stack-name todo-manager-dev-service

# Then delete infrastructure stack
aws cloudformation delete-stack --stack-name todo-manager-dev-infra
aws cloudformation wait stack-delete-complete --stack-name todo-manager-dev-infra

# Clean up ECR images (optional)
aws ecr list-images --repository-name todo-manager-dev --query 'imageIds[*]' --output json | \
aws ecr batch-delete-image --repository-name todo-manager-dev --image-ids file:///dev/stdin
```

## 📈 Scaling and Production Considerations

### Auto Scaling

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/todo-manager-dev-cluster/todo-manager-dev-service \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 2 \
    --max-capacity 10
```

### Production Deployment

For production, consider:

1. **Database**: Add RDS PostgreSQL to infrastructure template
2. **HTTPS**: Add ACM certificate and HTTPS listener to ALB
3. **Domain**: Add Route 53 hosted zone and records
4. **Monitoring**: Add CloudWatch dashboards and alarms
5. **Backup**: Add automated backup strategies
6. **Security**: Implement WAF, VPC Flow Logs, and GuardDuty

## 🎯 Key Improvements

1. **Fixed Deployment Order**: Infrastructure → Build → Push → Deploy Service
2. **Separate Stacks**: Better separation of concerns and lifecycle management
3. **Proper Dependencies**: Service stack properly references infrastructure exports
4. **Update Strategy**: Easy application updates without infrastructure changes
5. **Better Error Handling**: Clear failure points and troubleshooting steps
6. **Comprehensive Monitoring**: Detailed status checking and logging

The fixed deployment approach ensures reliable, repeatable deployments that follow AWS best practices and avoid the chicken-and-egg problem of the original script.
