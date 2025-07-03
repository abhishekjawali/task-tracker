#!/bin/bash

# Comprehensive ECS Deployment Script for Spring Boot ToDo Application
# Supports two-phase CloudFormation deployment to avoid chicken-and-egg problems

set -e  # Exit on any error

# Configuration
PROJECT_NAME="todo-app"
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
INFRASTRUCTURE_STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-infrastructure"
SERVICE_STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-service"
IMAGE_TAG="v1"

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

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Spring Boot ToDo Application to AWS ECS using CloudFormation

OPTIONS:
    --infrastructure-only    Deploy only infrastructure stack (Phase 1)
    --service-only          Deploy only ECS service stack (Phase 3)
    --app-only              Build image and deploy/update service only
    --setup-git             Configure CodeCommit integration
    --full-deploy           Complete deployment (all phases)
    --update                Update existing deployment
    --cleanup               Delete all resources
    --status                Check deployment status
    
    --project-name NAME     Project name (default: todo-app)
    --environment ENV       Environment (default: dev)
    --region REGION         AWS region (default: us-east-1)
    --image-tag TAG         finch image tag (default: latest)
    
    --help                  Show this help message

EXAMPLES:
    # Full deployment (recommended for first time)
    $0 --full-deploy
    
    # Deploy only infrastructure
    $0 --infrastructure-only
    
    # Update application code only
    $0 --app-only
    
    # Setup CodeCommit integration
    $0 --setup-git
    
    # Check deployment status
    $0 --status

DEPLOYMENT PHASES:
    Phase 1: Deploy infrastructure (VPC, ECR, ALB, ECS cluster)
    Phase 2: Build and push finch image to ECR
    Phase 3: Deploy ECS service and task definition

EOF
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check finch
    if ! command -v finch &> /dev/null; then
        print_error "finch is not installed. Please install it first."
        exit 1
    fi
    
    # Check Maven
    if ! command -v mvn &> /dev/null; then
        print_error "Maven is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    # Check finch daemon
    if ! finch info &> /dev/null; then
        print_error "finch daemon is not running. Please start finch."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Function to get AWS account ID
get_account_id() {
    aws sts get-caller-identity --query Account --output text
}

# Function to check if stack exists
stack_exists() {
    local stack_name=$1
    aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" &> /dev/null
}

# Function to wait for stack operation
wait_for_stack() {
    local stack_name=$1
    local operation=$2
    
    print_status "Waiting for stack $operation to complete: $stack_name"
    
    aws cloudformation wait "stack-${operation}-complete" \
        --stack-name "$stack_name" \
        --region "$AWS_REGION" || {
        print_error "Stack $operation failed for: $stack_name"
        
        # Show stack events for debugging
        print_status "Recent stack events:"
        aws cloudformation describe-stack-events \
            --stack-name "$stack_name" \
            --region "$AWS_REGION" \
            --query 'StackEvents[0:10].[Timestamp,ResourceStatus,ResourceType,LogicalResourceId,ResourceStatusReason]' \
            --output table
        
        exit 1
    }
    
    print_success "Stack $operation completed: $stack_name"
}

# Function to deploy infrastructure stack
deploy_infrastructure() {
    print_status "Deploying infrastructure stack..."
    
    if stack_exists "$INFRASTRUCTURE_STACK_NAME"; then
        print_status "Updating existing infrastructure stack..."
        aws cloudformation update-stack \
            --stack-name "$INFRASTRUCTURE_STACK_NAME" \
            --template-body file://infrastructure-template.yaml \
            --parameters ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
                        ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$AWS_REGION" || {
            if [[ $? -eq 255 ]]; then
                print_warning "No updates to be performed on infrastructure stack"
                return 0
            else
                print_error "Failed to update infrastructure stack"
                exit 1
            fi
        }
        wait_for_stack "$INFRASTRUCTURE_STACK_NAME" "update"
    else
        print_status "Creating new infrastructure stack..."
        aws cloudformation create-stack \
            --stack-name "$INFRASTRUCTURE_STACK_NAME" \
            --template-body file://infrastructure-template.yaml \
            --parameters ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
                        ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$AWS_REGION"
        wait_for_stack "$INFRASTRUCTURE_STACK_NAME" "create"
    fi
    
    # Get ECR repository URI
    ECR_URI=$(aws cloudformation describe-stacks \
        --stack-name "$INFRASTRUCTURE_STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryURI`].OutputValue' \
        --output text)
    
    print_success "Infrastructure deployed successfully"
    print_status "ECR Repository: $ECR_URI"
}

# Function to build and push finch image
build_and_push_image() {
    print_status "Building and pushing finch image..."
    
    # Get ECR repository URI from CloudFormation output
    ECR_URI=$(aws cloudformation describe-stacks \
        --stack-name "$INFRASTRUCTURE_STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`ECRRepositoryURI`].OutputValue' \
        --output text)
    
    if [[ -z "$ECR_URI" ]]; then
        print_error "Could not get ECR repository URI. Make sure infrastructure is deployed."
        exit 1
    fi
    
    # Build Maven project
    print_status "Building Maven project..."
    mvn clean package -DskipTests
    
    # Build finch image
    print_status "Building finch image..."
    finch build --platform linux/amd64 -t "${PROJECT_NAME}:${IMAGE_TAG}" .
    
    # Tag image for ECR
    finch tag "${PROJECT_NAME}:${IMAGE_TAG}" "${ECR_URI}:${IMAGE_TAG}"
    
    # Login to ECR
    print_status "Logging in to ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | \
        finch login --username AWS --password-stdin "$ECR_URI"
    
    # Push image to ECR
    print_status "Pushing image to ECR..."
    finch push "${ECR_URI}:${IMAGE_TAG}"
    
    print_success "Image built and pushed successfully"
    print_status "Image URI: ${ECR_URI}:${IMAGE_TAG}"
}

# Function to deploy ECS service
deploy_service() {
    print_status "Deploying ECS service..."
    
    if stack_exists "$SERVICE_STACK_NAME"; then
        print_status "Updating existing service stack..."
        aws cloudformation update-stack \
            --stack-name "$SERVICE_STACK_NAME" \
            --template-body file://ecs-service-template.yaml \
            --parameters ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
                        ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
                        ParameterKey=ImageTag,ParameterValue="$IMAGE_TAG" \
            --capabilities CAPABILITY_IAM \
            --region "$AWS_REGION" || {
            if [[ $? -eq 255 ]]; then
                print_warning "No updates to be performed on service stack"
                return 0
            else
                print_error "Failed to update service stack"
                exit 1
            fi
        }
        wait_for_stack "$SERVICE_STACK_NAME" "update"
    else
        print_status "Creating new service stack..."
        aws cloudformation create-stack \
            --stack-name "$SERVICE_STACK_NAME" \
            --template-body file://ecs-service-template.yaml \
            --parameters ParameterKey=ProjectName,ParameterValue="$PROJECT_NAME" \
                        ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
                        ParameterKey=ImageTag,ParameterValue="$IMAGE_TAG" \
            --capabilities CAPABILITY_IAM \
            --region "$AWS_REGION"
        wait_for_stack "$SERVICE_STACK_NAME" "create"
    fi
    
    print_success "ECS service deployed successfully"
}

# Function to setup CodeCommit integration
setup_git() {
    print_status "Setting up CodeCommit integration..."
    
    # Get CodeCommit repository URL
    CODECOMMIT_URL=$(aws cloudformation describe-stacks \
        --stack-name "$INFRASTRUCTURE_STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`CodeCommitRepositoryCloneUrlHttp`].OutputValue' \
        --output text)
    
    if [[ -z "$CODECOMMIT_URL" ]]; then
        print_error "Could not get CodeCommit repository URL. Make sure infrastructure is deployed."
        exit 1
    fi
    
    # Check if git is initialized
    if [[ ! -d ".git" ]]; then
        print_status "Initializing git repository..."
        git init
    fi
    
    # Add CodeCommit as remote
    if git remote get-url codecommit &> /dev/null; then
        print_status "Updating CodeCommit remote..."
        git remote set-url codecommit "$CODECOMMIT_URL"
    else
        print_status "Adding CodeCommit remote..."
        git remote add codecommit "$CODECOMMIT_URL"
    fi
    
    # Create .gitignore if it doesn't exist
    if [[ ! -f ".gitignore" ]]; then
        cat > .gitignore << EOF
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

### finch ###
.finchignore
EOF
    fi
    
    print_success "CodeCommit integration setup complete"
    print_status "CodeCommit URL: $CODECOMMIT_URL"
    print_status "To push code: git push codecommit main"
}

# Function to check deployment status
check_status() {
    print_status "Checking deployment status..."
    
    # Check infrastructure stack
    if stack_exists "$INFRASTRUCTURE_STACK_NAME"; then
        INFRA_STATUS=$(aws cloudformation describe-stacks \
            --stack-name "$INFRASTRUCTURE_STACK_NAME" \
            --region "$AWS_REGION" \
            --query 'Stacks[0].StackStatus' \
            --output text)
        print_status "Infrastructure Stack: $INFRA_STATUS"
        
        if [[ "$INFRA_STATUS" == "CREATE_COMPLETE" || "$INFRA_STATUS" == "UPDATE_COMPLETE" ]]; then
            # Get ALB URL
            ALB_URL=$(aws cloudformation describe-stacks \
                --stack-name "$INFRASTRUCTURE_STACK_NAME" \
                --region "$AWS_REGION" \
                --query 'Stacks[0].Outputs[?OutputKey==`ApplicationLoadBalancerURL`].OutputValue' \
                --output text)
            print_status "Application Load Balancer: $ALB_URL"
        fi
    else
        print_warning "Infrastructure stack not found"
    fi
    
    # Check service stack
    if stack_exists "$SERVICE_STACK_NAME"; then
        SERVICE_STATUS=$(aws cloudformation describe-stacks \
            --stack-name "$SERVICE_STACK_NAME" \
            --region "$AWS_REGION" \
            --query 'Stacks[0].StackStatus' \
            --output text)
        print_status "Service Stack: $SERVICE_STATUS"
        
        if [[ "$SERVICE_STATUS" == "CREATE_COMPLETE" || "$SERVICE_STATUS" == "UPDATE_COMPLETE" ]]; then
            # Check ECS service status
            ECS_SERVICE_STATUS=$(aws ecs describe-services \
                --cluster "${PROJECT_NAME}-${ENVIRONMENT}-cluster" \
                --services "${PROJECT_NAME}-${ENVIRONMENT}-service" \
                --region "$AWS_REGION" \
                --query 'services[0].status' \
                --output text 2>/dev/null || echo "NOT_FOUND")
            
            if [[ "$ECS_SERVICE_STATUS" != "NOT_FOUND" ]]; then
                print_status "ECS Service Status: $ECS_SERVICE_STATUS"
                
                # Get running task count
                RUNNING_TASKS=$(aws ecs describe-services \
                    --cluster "${PROJECT_NAME}-${ENVIRONMENT}-cluster" \
                    --services "${PROJECT_NAME}-${ENVIRONMENT}-service" \
                    --region "$AWS_REGION" \
                    --query 'services[0].runningCount' \
                    --output text)
                
                DESIRED_TASKS=$(aws ecs describe-services \
                    --cluster "${PROJECT_NAME}-${ENVIRONMENT}-cluster" \
                    --services "${PROJECT_NAME}-${ENVIRONMENT}-service" \
                    --region "$AWS_REGION" \
                    --query 'services[0].desiredCount' \
                    --output text)
                
                print_status "Tasks: $RUNNING_TASKS/$DESIRED_TASKS running"
                
                if [[ "$RUNNING_TASKS" -eq "$DESIRED_TASKS" && "$RUNNING_TASKS" -gt 0 ]]; then
                    print_success "Application is healthy and running!"
                    if [[ -n "$ALB_URL" ]]; then
                        print_status "Access your application at: $ALB_URL"
                        print_status "Health check: $ALB_URL/actuator/health"
                    fi
                fi
            fi
        fi
    else
        print_warning "Service stack not found"
    fi
}

# Function to cleanup resources
cleanup() {
    print_warning "This will delete ALL resources created by this deployment!"
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_status "Cleanup cancelled"
        exit 0
    fi
    
    print_status "Cleaning up resources..."
    
    # Delete service stack first
    if stack_exists "$SERVICE_STACK_NAME"; then
        print_status "Deleting service stack..."
        aws cloudformation delete-stack \
            --stack-name "$SERVICE_STACK_NAME" \
            --region "$AWS_REGION"
        wait_for_stack "$SERVICE_STACK_NAME" "delete"
    fi
    
    # Delete infrastructure stack
    if stack_exists "$INFRASTRUCTURE_STACK_NAME"; then
        print_status "Deleting infrastructure stack..."
        aws cloudformation delete-stack \
            --stack-name "$INFRASTRUCTURE_STACK_NAME" \
            --region "$AWS_REGION"
        wait_for_stack "$INFRASTRUCTURE_STACK_NAME" "delete"
    fi
    
    print_success "Cleanup completed"
}

# Function to perform full deployment
full_deploy() {
    print_status "Starting full deployment..."
    check_prerequisites
    deploy_infrastructure
    build_and_push_image
    deploy_service
    print_success "Full deployment completed!"
    check_status
}

# Function to update deployment
update_deployment() {
    print_status "Updating deployment..."
    check_prerequisites
    
    # Update infrastructure if template changed
    if [[ infrastructure-template.yaml -nt "$HOME/.aws-deploy-last-infra" ]]; then
        print_status "Infrastructure template changed, updating..."
        deploy_infrastructure
        touch "$HOME/.aws-deploy-last-infra"
    fi
    
    # Always build and push new image for updates
    build_and_push_image
    deploy_service
    
    print_success "Deployment updated!"
    check_status
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --infrastructure-only)
            check_prerequisites
            deploy_infrastructure
            exit 0
            ;;
        --service-only)
            check_prerequisites
            deploy_service
            exit 0
            ;;
        --app-only)
            check_prerequisites
            build_and_push_image
            deploy_service
            exit 0
            ;;
        --setup-git)
            setup_git
            exit 0
            ;;
        --full-deploy)
            full_deploy
            exit 0
            ;;
        --update)
            update_deployment
            exit 0
            ;;
        --cleanup)
            cleanup
            exit 0
            ;;
        --status)
            check_status
            exit 0
            ;;
        --project-name)
            PROJECT_NAME="$2"
            INFRASTRUCTURE_STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-infrastructure"
            SERVICE_STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-service"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            INFRASTRUCTURE_STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-infrastructure"
            SERVICE_STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-service"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --image-tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# If no arguments provided, show usage
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi
