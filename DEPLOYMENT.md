# ToDo Manager - AWS ECS Deployment Guide

This guide walks you through deploying the ToDo Manager Spring Boot application to AWS ECS using Fargate.

## Architecture Overview

The deployment creates the following AWS resources:

### Networking
- **VPC** with CIDR 10.0.0.0/16
- **2 Public Subnets** (10.0.1.0/24, 10.0.2.0/24) for ALB
- **2 Private Subnets** (10.0.3.0/24, 10.0.4.0/24) for ECS tasks
- **NAT Gateway** in public subnet for outbound internet access
- **Internet Gateway** for public internet access

### Application Infrastructure
- **ECR Repository** for Docker images
- **CodeCommit Repository** for source code
- **ECS Fargate Cluster** for container orchestration
- **Application Load Balancer** for internet-facing access
- **CloudWatch Log Groups** for application logs

### Security
- **Security Groups** with least-privilege access
- **IAM Roles** for ECS task execution and application access
- **ECR Image Scanning** enabled for vulnerability detection

## Prerequisites

Before deploying, ensure you have:

1. **AWS CLI** installed and configured
   ```bash
   aws --version
   aws configure list
   ```

2. **Docker** installed and running
   ```bash
   docker --version
   docker info
   ```

3. **Java 11+** and **Maven** for building the application
   ```bash
   java -version
   ./mvnw --version
   ```

4. **AWS Permissions** - Your AWS user/role needs permissions for:
   - CloudFormation (full access)
   - ECS (full access)
   - ECR (full access)
   - CodeCommit (full access)
   - VPC and EC2 (for networking)
   - IAM (for role creation)
   - CloudWatch (for logging)
   - Elastic Load Balancing

## Quick Deployment

### Option 1: Full Automated Deployment

```bash
# Make sure you're in the project root directory
cd /Users/jawalia/Documents/Technical/levelup/togithub/task-tracker

# Run the deployment script
./deploy.sh
```

This script will:
1. Deploy the CloudFormation infrastructure
2. Build the Spring Boot application
3. Create and push Docker image to ECR
4. Update the ECS service
5. Set up CodeCommit repository

### Option 2: Step-by-Step Deployment

#### Step 1: Deploy Infrastructure

```bash
aws cloudformation deploy \
    --template-file cloudformation-template.yaml \
    --stack-name todo-manager-dev-stack \
    --parameter-overrides \
        ApplicationName=todo-manager \
        Environment=dev \
    --capabilities CAPABILITY_NAMED_IAM \
    --region us-east-1
```

#### Step 2: Build Application

```bash
./mvnw clean package -DskipTests
```

#### Step 3: Build and Push Docker Image

```bash
# Get ECR repository URI
ECR_URI=$(aws cloudformation describe-stacks \
    --stack-name todo-manager-dev-stack \
    --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryURI`].OutputValue' \
    --output text)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URI

# Build and push image
docker build -t todo-manager:latest .
docker tag todo-manager:latest $ECR_URI:latest
docker push $ECR_URI:latest
```

#### Step 4: Update ECS Service

```bash
# Get ECS cluster and service names
ECS_CLUSTER=$(aws cloudformation describe-stacks \
    --stack-name todo-manager-dev-stack \
    --query 'Stacks[0].Outputs[?OutputKey==`ECSClusterName`].OutputValue' \
    --output text)

ECS_SERVICE=$(aws cloudformation describe-stacks \
    --stack-name todo-manager-dev-stack \
    --query 'Stacks[0].Outputs[?OutputKey==`ECSServiceName`].OutputValue' \
    --output text)

# Force new deployment
aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --force-new-deployment
```

## Configuration Options

### CloudFormation Parameters

You can customize the deployment by modifying these parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| ApplicationName | todo-manager | Name of the application |
| Environment | dev | Environment (dev/staging/prod) |
| ContainerPort | 8080 | Port the application runs on |
| DesiredCount | 2 | Number of ECS tasks |
| TaskCpu | 512 | CPU units (256, 512, 1024, 2048, 4096) |
| TaskMemory | 1024 | Memory in MB |

### Environment Variables

The application supports these environment variables:

- `SPRING_PROFILES_ACTIVE=prod` - Activates production profile
- `SERVER_PORT=8080` - Application port
- `SPRING_DATASOURCE_URL` - Database connection URL
- `SPRING_DATASOURCE_USERNAME` - Database username
- `SPRING_DATASOURCE_PASSWORD` - Database password

## Database Configuration

### Development (H2)
The application runs with H2 in-memory database by default for development.

### Production (PostgreSQL)
For production, you'll need to set up PostgreSQL. Options include:

1. **Amazon RDS PostgreSQL**
2. **Amazon Aurora PostgreSQL**
3. **Self-managed PostgreSQL on EC2**

Update the database configuration in the ECS task definition:

```yaml
Environment:
  - Name: SPRING_DATASOURCE_URL
    Value: jdbc:postgresql://your-rds-endpoint:5432/todoapp
  - Name: SPRING_DATASOURCE_USERNAME
    Value: todouser
  - Name: SPRING_DATASOURCE_PASSWORD
    Value: your-secure-password
```

## Monitoring and Troubleshooting

### Application Logs

View application logs in CloudWatch:

```bash
aws logs tail /ecs/todo-manager-dev --follow
```

### ECS Service Status

Check ECS service status:

```bash
aws ecs describe-services \
    --cluster todo-manager-dev-cluster \
    --services todo-manager-dev-service
```

### Health Check

The application exposes health check endpoints:

- Health: `http://your-alb-url/actuator/health`
- Info: `http://your-alb-url/actuator/info`

### Common Issues

1. **Task Fails to Start**
   - Check CloudWatch logs for startup errors
   - Verify ECR image exists and is accessible
   - Check task definition resource limits

2. **Health Check Failures**
   - Ensure application starts within 60 seconds
   - Verify `/actuator/health` endpoint is accessible
   - Check security group allows ALB to reach container port

3. **Database Connection Issues**
   - Verify database credentials
   - Check network connectivity from private subnets
   - Ensure database security group allows connections

## Scaling

### Auto Scaling

To enable auto scaling, add an ECS Service Auto Scaling configuration:

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/todo-manager-dev-cluster/todo-manager-dev-service \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 2 \
    --max-capacity 10

# Create scaling policy
aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --resource-id service/todo-manager-dev-cluster/todo-manager-dev-service \
    --scalable-dimension ecs:service:DesiredCount \
    --policy-name cpu-scaling \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration file://scaling-policy.json
```

### Manual Scaling

```bash
aws ecs update-service \
    --cluster todo-manager-dev-cluster \
    --service todo-manager-dev-service \
    --desired-count 4
```

## Security Best Practices

1. **Network Security**
   - ECS tasks run in private subnets
   - Only ALB has public access
   - Security groups follow least-privilege principle

2. **Container Security**
   - Non-root user in Docker container
   - ECR image scanning enabled
   - Minimal base image (JRE slim)

3. **IAM Security**
   - Separate execution and task roles
   - Minimal required permissions
   - No hardcoded credentials

4. **Application Security**
   - Actuator endpoints secured
   - Error details hidden in production
   - Database credentials via environment variables

## Cost Optimization

1. **Use Fargate Spot** for non-critical workloads
2. **Right-size** CPU and memory allocations
3. **Enable** ECR lifecycle policies for image cleanup
4. **Monitor** CloudWatch costs and set up billing alerts
5. **Use** Application Load Balancer efficiently

## Cleanup

To remove all resources:

```bash
# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name todo-manager-dev-stack

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name todo-manager-dev-stack

# Clean up ECR images (optional)
aws ecr list-images --repository-name todo-manager-dev --query 'imageIds[*]' --output json | \
aws ecr batch-delete-image --repository-name todo-manager-dev --image-ids file:///dev/stdin
```

## Support

For issues and questions:

1. Check CloudWatch logs for application errors
2. Review ECS service events for deployment issues
3. Verify CloudFormation stack events for infrastructure problems
4. Check AWS service health dashboard for regional issues

## Next Steps

After successful deployment, consider:

1. **Set up CI/CD pipeline** with AWS CodePipeline
2. **Configure custom domain** with Route 53 and ACM
3. **Add database** with Amazon RDS
4. **Implement monitoring** with CloudWatch dashboards
5. **Set up alerts** for application and infrastructure metrics
6. **Configure backup** strategies for data persistence
