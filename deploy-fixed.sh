#!/bin/bash

# ToDo Manager ECS Deployment Script - FIXED VERSION
# This script deploys infrastructure first, then builds and pushes the image, then deploys ECS service

set -e

# Configuration
APPLICATION_NAME="todo-manager"
ENVIRONMENT="dev"
AWS_REGION="us-west-2"
INFRA_STACK_NAME="${APPLICATION_NAME}-${ENVIRONMENT}-infra"
SERVICE_STACK_NAME="${APPLICATION_NAME}-${ENVIRONMENT}-service"
IMAGE_TAG=v1

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

# Function to check if finch is running
check_finch() {
    if ! command -v finch &> /dev/null; then
        print_error "finch is not installed. Please install finch first."
        exit 1
    fi
    
    if ! finch info &> /dev/null; then
        print_error "finch is not running. Please start finch first."
        exit 1
    fi
    
    print_success "finch is running"
}

# Function to deploy infrastructure stack
deploy_infrastructure() {
    print_status "Deploying infrastructure CloudFormation stack..."
    
    aws cloudformation deploy \
        --template-file infrastructure-template.yaml \
        --stack-name $INFRA_STACK_NAME \
        --parameter-overrides \
            ApplicationName=$APPLICATION_NAME \
            Environment=$ENVIRONMENT \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        print_success "Infrastructure stack deployed successfully"
    else
        print_error "Failed to deploy infrastructure stack"
        exit 1
    fi
}

# Function to get infrastructure stack outputs
get_infra_outputs() {
    print_status "Getting infrastructure stack outputs..."
    
    ECR_URI=$(aws cloudformation describe-stacks \
        --stack-name $INFRA_STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryURI`].OutputValue' \
        --output text)
    
    ALB_URL=$(aws cloudformation describe-stacks \
        --stack-name $INFRA_STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
        --output text)
    
    ECS_CLUSTER=$(aws cloudformation describe-stacks \
        --stack-name $INFRA_STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ECSClusterName`].OutputValue' \
        --output text)
    
    CODECOMMIT_URL=$(aws cloudformation describe-stacks \
        --stack-name $INFRA_STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`CodeCommitRepositoryCloneUrlHttp`].OutputValue' \
        --output text)
    
    print_success "Retrieved infrastructure outputs"
    echo "ECR URI: $ECR_URI"
    echo "ALB URL: $ALB_URL"
    echo "ECS Cluster: $ECS_CLUSTER"
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

# Function to create finchfile if it doesn't exist
create_finchfile() {
    if [ ! -f "finchfile" ]; then
        print_status "finchfile not found, but it should exist. Please check the project structure."
        exit 1
    else
        print_status "Using existing finchfile"
    fi
}

# Function to build and push finch image
build_and_push_image() {
    print_status "Building finch image..."
    
    # Get ECR login token
    aws ecr get-login-password --region $AWS_REGION --profile "$AWS_PROFILE" | finch login --username AWS --password-stdin $ECR_URI
    
    # Build the image
    finch build --platform linux/amd64 -t $APPLICATION_NAME:latest .
    
    if [ $? -eq 0 ]; then
        print_success "finch image built successfully"
    else
        print_error "Failed to build finch image"
        exit 1
    fi
    
    # Tag the image
    
    finch tag $APPLICATION_NAME:latest $ECR_URI:latest
    finch tag $APPLICATION_NAME:latest $ECR_URI:$IMAGE_TAG
    
    # Push the image
    print_status "Pushing finch image to ECR..."
    finch push $ECR_URI:latest
    finch push $ECR_URI:$IMAGE_TAG
    
    if [ $? -eq 0 ]; then
        print_success "finch image pushed successfully"
        echo "Image tags: latest, $IMAGE_TAG"
    else
        print_error "Failed to push finch image"
        exit 1
    fi
}

# Function to deploy ECS service
deploy_ecs_service() {
    print_status "Deploying ECS service CloudFormation stack..."
    
    aws cloudformation deploy \
        --template-file ecs-service-template.yaml \
        --stack-name $SERVICE_STACK_NAME \
        --parameter-overrides \
            ApplicationName=$APPLICATION_NAME \
            Environment=$ENVIRONMENT \
            ImageTag=$IMAGE_TAG \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        print_success "ECS service stack deployed successfully"
    else
        print_error "Failed to deploy ECS service stack"
        exit 1
    fi
}

# Function to get service stack outputs
get_service_outputs() {
    print_status "Getting service stack outputs..."
    
    ECS_SERVICE=$(aws cloudformation describe-stacks \
        --stack-name $SERVICE_STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ECSServiceName`].OutputValue' \
        --output text)
    
    print_success "Retrieved service outputs"
    echo "ECS Service: $ECS_SERVICE"
}

# Function to wait for service to be stable
wait_for_service() {
    print_status "Waiting for ECS service to become stable..."
    
    aws ecs wait services-stable \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --region $AWS_REGION
    
    if [ $? -eq 0 ]; then
        print_success "ECS service is stable and running"
    else
        print_warning "Service may still be starting up. Check the AWS console for status."
    fi
}

# Function to show deployment status
show_deployment_status() {
    print_status "Deployment Status:"
    echo "===================="
    echo "Application: $APPLICATION_NAME"
    echo "Environment: $ENVIRONMENT"
    echo "Region: $AWS_REGION"
    echo "Infrastructure Stack: $INFRA_STACK_NAME"
    echo "Service Stack: $SERVICE_STACK_NAME"
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
    echo ""
    print_status "To update the application:"
    echo "1. Make code changes"
    echo "2. Run: ./deploy-fixed.sh --update-only"
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

# Function to update existing deployment
update_deployment() {
    print_status "Updating existing deployment..."
    
    # Get existing outputs
    get_infra_outputs
    
    # Build and push new image
    build_application
    build_and_push_image
    
    # Update ECS service with new image
    deploy_ecs_service
    get_service_outputs
    wait_for_service
    
    print_success "Deployment updated successfully!"
}

# Main execution
main() {
    echo "========================================="
    echo "ToDo Manager ECS Deployment Script (Fixed)"
    echo "========================================="
    echo ""
    
    # Parse command line arguments
    DEPLOY_INFRA=true
    BUILD_APP=true
    PUSH_IMAGE=true
    DEPLOY_SERVICE=true
    UPDATE_ONLY=false
    
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
            --skip-service)
                DEPLOY_SERVICE=false
                shift
                ;;
            --update-only)
                UPDATE_ONLY=true
                DEPLOY_INFRA=false
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-infra    Skip infrastructure deployment"
                echo "  --skip-build    Skip application build"
                echo "  --skip-push     Skip finch image push"
                echo "  --skip-service  Skip ECS service deployment"
                echo "  --update-only   Only update app (skip infrastructure)"
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
    check_finch
    
    if [ "$UPDATE_ONLY" = true ]; then
        update_deployment
        return
    fi
    
    # Step 1: Deploy infrastructure (VPC, ECR, ALB, etc.)
    if [ "$DEPLOY_INFRA" = true ]; then
        deploy_infrastructure
    fi
    
    # Get infrastructure outputs
    get_infra_outputs
    
    # Step 2: Build application
    if [ "$BUILD_APP" = true ]; then
        build_application
        create_finchfile
    fi
    
    # Step 3: Build and push finch image
    if [ "$PUSH_IMAGE" = true ]; then
        build_and_push_image
    fi
    
    # Step 4: Deploy ECS service (now that image exists)
    if [ "$DEPLOY_SERVICE" = true ]; then
        deploy_ecs_service
        get_service_outputs
        wait_for_service
    fi
    
    # Setup CodeCommit
    setup_codecommit
    
    # Show final status
    show_deployment_status
}

# Run main function
main "$@"
