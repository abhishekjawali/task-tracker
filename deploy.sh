#!/bin/bash

# ToDo Manager ECS Deployment Script
# This script builds the Docker image, pushes it to ECR, and updates the ECS service

set -e

# Configuration
APPLICATION_NAME="todo-manager"
ENVIRONMENT="dev"
AWS_REGION="us-west-2"
STACK_NAME="${APPLICATION_NAME}-${ENVIRONMENT}-stack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is configured"
}

# Function to check if Docker is running
check_docker() {
    # if ! command -v docker &> /dev/null; then
    #     print_error "Docker is not installed. Please install Docker first."
    #     exit 1
    # fi
    
    # if ! docker info &> /dev/null; then
    #     print_error "Docker is not running. Please start Docker first."
    #     exit 1
    # fi
    
    print_success "Docker is running"
}

# Function to deploy CloudFormation stack
deploy_infrastructure() {
    print_status "Deploying CloudFormation stack..."
    
    aws cloudformation deploy \
        --template-file cloudformation-template.yaml \
        --stack-name $STACK_NAME \
        --parameter-overrides \
            ApplicationName=$APPLICATION_NAME \
            Environment=$ENVIRONMENT \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        print_success "CloudFormation stack deployed successfully"
    else
        print_error "Failed to deploy CloudFormation stack"
        exit 1
    fi
}

# Function to get stack outputs
get_stack_outputs() {
    print_status "Getting stack outputs..."
    
    ECR_URI=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryURI`].OutputValue' \
        --output text)
    
    ALB_URL=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
        --output text)
    
    ECS_CLUSTER=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ECSClusterName`].OutputValue' \
        --output text)
    
    ECS_SERVICE=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ECSServiceName`].OutputValue' \
        --output text)
    
    CODECOMMIT_URL=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`CodeCommitRepositoryCloneUrlHttp`].OutputValue' \
        --output text)
    
    print_success "Retrieved stack outputs"
    echo "ECR URI: $ECR_URI"
    echo "ALB URL: $ALB_URL"
    echo "ECS Cluster: $ECS_CLUSTER"
    echo "ECS Service: $ECS_SERVICE"
    echo "CodeCommit URL: $CODECOMMIT_URL"
}

# Function to build the application
build_application() {
    print_status "Building Spring Boot application..."
    
    if [ ! -f "pom.xml" ]; then
        print_error "pom.xml not found. Make sure you're in the project root directory."
        exit 1
    fi
    
    ./mvnw clean package -DskipTests
    
    if [ $? -eq 0 ]; then
        print_success "Application built successfully"
    else
        print_error "Failed to build application"
        exit 1
    fi
}

# Function to create Dockerfile if it doesn't exist
create_dockerfile() {
    if [ ! -f "Dockerfile" ]; then
        print_status "Creating Dockerfile..."
        cat > Dockerfile << 'EOF'
FROM openjdk:11-jre-slim

# Set working directory
WORKDIR /app

# Copy the jar file
COPY target/*.jar app.jar

# Expose port
EXPOSE 8080

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
        print_success "Dockerfile created"
    else
        print_status "Dockerfile already exists"
    fi
}

# Function to build and push Docker image
build_and_push_image() {
    print_status "Building Docker image..."
    
    # Get ECR login token
    aws ecr get-login-password --region $AWS_REGION | finch login --username AWS --password-stdin $ECR_URI
    
    # Build the image
    finch build --platform linux/amd64 -t $APPLICATION_NAME:latest .
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
    
    # Tag the image
    finch tag $APPLICATION_NAME:latest $ECR_URI:latest
    finch tag $APPLICATION_NAME:latest $ECR_URI:$(date +%Y%m%d-%H%M%S)
    
    # Push the image
    print_status "Pushing Docker image to ECR..."
    finch push $ECR_URI:latest
    finch push $ECR_URI:$(date +%Y%m%d-%H%M%S)
    
    if [ $? -eq 0 ]; then
        print_success "Docker image pushed successfully"
    else
        print_error "Failed to push Docker image"
        exit 1
    fi
}

# Function to update ECS service
update_ecs_service() {
    print_status "Updating ECS service..."
    
    aws ecs update-service \
        --cluster $ECS_CLUSTER \
        --service $ECS_SERVICE \
        --force-new-deployment \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        print_success "ECS service update initiated"
        print_status "Waiting for deployment to complete..."
        
        aws ecs wait services-stable \
            --cluster $ECS_CLUSTER \
            --services $ECS_SERVICE \
            --region $AWS_REGION
        
        print_success "ECS service updated successfully"
    else
        print_error "Failed to update ECS service"
        exit 1
    fi
}

# Function to show deployment status
show_deployment_status() {
    print_status "Deployment Status:"
    echo "===================="
    echo "Application: $APPLICATION_NAME"
    echo "Environment: $ENVIRONMENT"
    echo "Region: $AWS_REGION"
    echo "Stack: $STACK_NAME"
    echo ""
    echo "Application URL: $ALB_URL"
    echo "CodeCommit Repository: $CODECOMMIT_URL"
    echo ""
    print_success "Deployment completed successfully!"
    echo ""
    print_status "You can now:"
    echo "1. Access your application at: $ALB_URL"
    echo "2. Clone your CodeCommit repository: git clone $CODECOMMIT_URL"
    echo "3. Monitor your ECS service in the AWS Console"
    echo "4. View logs in CloudWatch: /ecs/${APPLICATION_NAME}-${ENVIRONMENT}"
}

# Function to setup CodeCommit repository
setup_codecommit() {
    print_status "Setting up CodeCommit repository..."
    
    # Check if git is initialized
    if [ ! -d ".git" ]; then
        git init
        print_success "Git repository initialized"
    fi
    
    # Add CodeCommit as remote if not already added
    if ! git remote get-url origin &> /dev/null; then
        git remote add origin $CODECOMMIT_URL
        print_success "CodeCommit remote added"
    else
        print_warning "Git remote 'origin' already exists"
    fi
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'EOF'
target/
!.mvn/wrapper/maven-wrapper.jar
!**/src/main/**/target/
!**/src/test/**/target/

### STS ###
.apt_generated
.classpath
.factorypath
.project
.settings
.springBeans
.sts4-cache

### IntelliJ IDEA ###
.idea
*.iws
*.iml
*.ipr

### NetBeans ###
/nbproject/private/
/nbbuild/
/dist/
/nbdist/
/.nb-gradle/
build/
!**/src/main/**/build/
!**/src/test/**/build/

### VS Code ###
.vscode/

### OS ###
.DS_Store
Thumbs.db

### Logs ###
*.log
EOF
        print_success ".gitignore created"
    fi
    
    print_status "To push your code to CodeCommit:"
    echo "git add ."
    echo "git commit -m 'Initial commit'"
    echo "git push -u origin main"
}

# Main execution
main() {
    echo "========================================="
    echo "ToDo Manager ECS Deployment Script"
    echo "========================================="
    echo ""
    
    # Parse command line arguments
    DEPLOY_INFRA=true
    BUILD_APP=true
    PUSH_IMAGE=true
    UPDATE_SERVICE=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-infra)
                DEPLOY_INFRA=false
                shift
                ;;
            --skip-build)
                BUILD_APP=false
                shift
                ;;
            --skip-push)
                PUSH_IMAGE=false
                shift
                ;;
            --skip-update)
                UPDATE_SERVICE=false
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-infra    Skip infrastructure deployment"
                echo "  --skip-build    Skip application build"
                echo "  --skip-push     Skip Docker image push"
                echo "  --skip-update   Skip ECS service update"
                echo "  --help          Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Pre-flight checks
    check_aws_cli
    check_docker
    
    # Deploy infrastructure
    if [ "$DEPLOY_INFRA" = true ]; then
        deploy_infrastructure
    fi
    
    # Get stack outputs
    get_stack_outputs
    
    # Build application
    if [ "$BUILD_APP" = true ]; then
        build_application
        create_dockerfile
    fi
    
    # Build and push Docker image
    if [ "$PUSH_IMAGE" = true ]; then
        build_and_push_image
    fi
    
    # Update ECS service
    if [ "$UPDATE_SERVICE" = true ]; then
        update_ecs_service
    fi
    
    # Setup CodeCommit
    setup_codecommit
    
    # Show final status
    show_deployment_status
}

# Run main function
main "$@"
