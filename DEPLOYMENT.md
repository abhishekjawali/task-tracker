# ECS Deployment Guide for Spring Boot ToDo Application

This guide provides comprehensive instructions for deploying the Spring Boot ToDo application to AWS ECS using a two-phase CloudFormation approach.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Deployment Phases](#deployment-phases)
5. [Configuration](#configuration)
6. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)
7. [Maintenance](#maintenance)
8. [Cleanup](#cleanup)

## Architecture Overview

The deployment creates the following AWS resources:

### Infrastructure Components
- **VPC**: Custom VPC with 2 public and 2 private subnets across 2 AZs
- **NAT Gateway**: For outbound internet access from private subnets
- **Application Load Balancer**: Internet-facing ALB in public subnets
- **ECS Fargate Cluster**: Container orchestration platform
- **ECR Repository**: Private Docker image registry
- **CodeCommit Repository**: Source code repository
- **CloudWatch Logs**: Centralized logging
- **IAM Roles**: Least-privilege security roles

### Application Components
- **ECS Service**: Manages desired number of tasks
- **Task Definition**: Container configuration and resource allocation
- **Auto Scaling**: CPU and memory-based scaling policies
- **Health Checks**: Application and load balancer health monitoring
- **Security Groups**: Network-level security controls

## Prerequisites

### Required Tools
- **AWS CLI v2**: Latest version with configured credentials
- **Docker**: For building container images
- **Maven 3.6+**: For building the Spring Boot application
- **Git**: For version control and CodeCommit integration

### AWS Permissions
Your AWS user/role needs the following permissions:
- CloudFormation: Full access
- ECS: Full access
- ECR: Full access
- EC2: VPC and security group management
- IAM: Role and policy management
- Application Load Balancer: Full access
- CloudWatch: Logs and metrics access
- CodeCommit: Repository management

### Installation Commands

```bash
# Install AWS CLI (macOS)
brew install awscli

# Install Docker (macOS)
brew install --cask docker

# Verify installations
aws --version
docker --version
mvn --version
```

## Quick Start

### 1. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format
```

### 2. Full Deployment (Recommended for first time)

```bash
# Navigate to project directory
cd /Users/jawalia/Documents/Technical/levelup/togithub/task-tracker

# Run full deployment
./deploy.sh --full-deploy
```

This command will:
1. Deploy infrastructure stack (VPC, ECR, ALB, ECS cluster)
2. Build Spring Boot application with Maven
3. Create and push Docker image to ECR
4. Deploy ECS service stack
5. Display application URL and status

### 3. Access Your Application

After successful deployment, the script will display:
- Application URL: `http://your-alb-dns-name`
- Health Check: `http://your-alb-dns-name/actuator/health`

## Deployment Phases

### Phase 1: Infrastructure Deployment

Deploy the foundational infrastructure without the ECS service:

```bash
./deploy.sh --infrastructure-only
```

**Resources Created:**
- VPC with public/private subnets
- Internet Gateway and NAT Gateway
- Security Groups
- Application Load Balancer and Target Group
- ECR Repository
- CodeCommit Repository
- ECS Cluster (empty)
- IAM Roles
- CloudWatch Log Group

### Phase 2: Application Build and Push

Build the Spring Boot application and push Docker image to ECR:

```bash
# This is automatically done in full deployment
# Or manually build and push:
mvn clean package -DskipTests
docker build -t todo-app:latest .
# ECR login and push handled by deploy script
```

### Phase 3: Service Deployment

Deploy the ECS service and task definition:

```bash
./deploy.sh --service-only
```

**Resources Created:**
- ECS Task Definition
- ECS Service
- Auto Scaling Target and Policies
- CloudWatch Alarms

## Configuration

### Environment Variables

The application supports the following environment variables in production:

| Variable | Default | Description |
|----------|---------|-------------|
| `SPRING_PROFILES_ACTIVE` | `prod` | Spring profile |
| `SPRING_DATASOURCE_URL` | H2 in-memory | Database connection URL |
| `SPRING_DATASOURCE_USERNAME` | `sa` | Database username |
| `SPRING_DATASOURCE_PASSWORD` | (empty) | Database password |
| `SERVER_PORT` | `8080` | Application port |
| `MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE` | `health,info` | Actuator endpoints |

### Deployment Script Options

```bash
# Deploy only infrastructure
./deploy.sh --infrastructure-only

# Deploy only ECS service
./deploy.sh --service-only

# Update application code only
./deploy.sh --app-only

# Setup CodeCommit integration
./deploy.sh --setup-git

# Check deployment status
./deploy.sh --status

# Update existing deployment
./deploy.sh --update

# Clean up all resources
./deploy.sh --cleanup

# Custom configuration
./deploy.sh --full-deploy --project-name my-app --environment prod --region us-west-2
```

### Database Configuration

#### Development (H2 In-Memory)
The application uses H2 in-memory database by default, suitable for development and testing.

#### Production (PostgreSQL)
For production, configure PostgreSQL:

1. **RDS PostgreSQL**: Create an RDS instance in the same VPC
2. **Update environment variables** in the ECS task definition:
   ```bash
   SPRING_DATASOURCE_URL=jdbc:postgresql://your-rds-endpoint:5432/todoapp
   SPRING_DATASOURCE_USERNAME=your-username
   SPRING_DATASOURCE_PASSWORD=your-password
   ```

3. **Update security groups** to allow ECS tasks to connect to RDS

## Monitoring and Troubleshooting

### CloudWatch Logs

Application logs are available in CloudWatch:
- Log Group: `/ecs/todo-app-dev`
- Log Stream: `ecs/todo-app-container/{task-id}`

```bash
# View logs using AWS CLI
aws logs tail /ecs/todo-app-dev --follow
```

### CloudWatch Metrics

Monitor the following metrics:
- **ECS Service**: CPU/Memory utilization, task count
- **Application Load Balancer**: Request count, response time, error rate
- **Target Group**: Healthy/unhealthy targets

### Health Checks

- **Application Health**: `http://your-alb-url/actuator/health`
- **Load Balancer Health**: Configured to check `/actuator/health`
- **Container Health**: Docker HEALTHCHECK using curl

### Common Issues

#### 1. Service Not Starting
```bash
# Check ECS service events
aws ecs describe-services --cluster todo-app-dev-cluster --services todo-app-dev-service

# Check task logs
aws logs tail /ecs/todo-app-dev --follow
```

#### 2. Load Balancer Health Check Failures
- Verify application is listening on port 8080
- Check security group allows traffic from ALB
- Ensure `/actuator/health` endpoint is accessible

#### 3. Image Pull Errors
- Verify ECR repository exists and contains the image
- Check ECS task execution role has ECR permissions
- Ensure image tag matches what's specified in task definition

#### 4. Database Connection Issues
- Verify database credentials in environment variables
- Check security group rules for database access
- Ensure database is accessible from ECS tasks

### Debugging Commands

```bash
# Check deployment status
./deploy.sh --status

# View CloudFormation stack events
aws cloudformation describe-stack-events --stack-name todo-app-dev-infrastructure

# Check ECS service status
aws ecs describe-services --cluster todo-app-dev-cluster --services todo-app-dev-service

# List running tasks
aws ecs list-tasks --cluster todo-app-dev-cluster --service-name todo-app-dev-service

# Execute command in running container
aws ecs execute-command --cluster todo-app-dev-cluster --task task-id --container todo-app-container --interactive --command "/bin/bash"
```

## Maintenance

### Updating the Application

#### Code Changes Only
```bash
./deploy.sh --app-only
```

#### Infrastructure Changes
```bash
./deploy.sh --update
```

#### Rolling Back
```bash
# Deploy previous image tag
./deploy.sh --app-only --image-tag previous-tag
```

### Scaling

#### Manual Scaling
```bash
# Update desired count in ecs-service-template.yaml
# Then redeploy service
./deploy.sh --service-only
```

#### Auto Scaling
Auto scaling is configured based on:
- CPU utilization > 70%
- Memory utilization > 80%

### Security Updates

#### Update Base Images
```bash
# Rebuild with latest base images
docker build --no-cache -t todo-app:latest .
./deploy.sh --app-only
```

#### Rotate Secrets
- Update database passwords in AWS Secrets Manager
- Update task definition to use new secrets
- Redeploy service

### Backup and Recovery

#### Application Data
- If using RDS: Automated backups and snapshots
- If using H2: Data is ephemeral (not recommended for production)

#### Configuration Backup
- CloudFormation templates are version controlled
- ECS task definitions are versioned automatically

## Cleanup

### Partial Cleanup
```bash
# Remove only ECS service (keep infrastructure)
aws cloudformation delete-stack --stack-name todo-app-dev-service
```

### Complete Cleanup
```bash
# Remove all resources
./deploy.sh --cleanup
```

**Warning**: This will delete all resources including:
- VPC and networking components
- ECR repository and all images
- CodeCommit repository
- CloudWatch logs
- All data (if using RDS, create snapshot first)

### Manual Cleanup (if script fails)
1. Delete ECS service stack
2. Delete infrastructure stack
3. Manually delete any remaining resources:
   - ECR images
   - CloudWatch log groups
   - NAT Gateway Elastic IPs

## Cost Optimization

### Development Environment
- Use Fargate Spot for non-critical workloads
- Scale down to 1 task during off-hours
- Use smaller instance sizes (0.25 vCPU, 512 MB)

### Production Environment
- Use reserved capacity for predictable workloads
- Implement proper auto-scaling policies
- Monitor and optimize resource utilization
- Use Application Load Balancer efficiently

### Estimated Costs (us-east-1)
- **Fargate**: ~$0.04/hour per task (0.5 vCPU, 1GB)
- **Application Load Balancer**: ~$0.0225/hour + $0.008/LCU-hour
- **NAT Gateway**: ~$0.045/hour + $0.045/GB processed
- **ECR**: $0.10/GB-month storage
- **CloudWatch Logs**: $0.50/GB ingested

## Support and Troubleshooting

### Getting Help
1. Check CloudWatch logs for application errors
2. Review CloudFormation stack events for infrastructure issues
3. Use AWS Support for service-specific problems
4. Consult AWS documentation for best practices

### Useful Resources
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS Fargate Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Spring Boot Actuator](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

**Note**: This deployment is designed for development and testing. For production use, consider additional security measures, monitoring, and backup strategies.
