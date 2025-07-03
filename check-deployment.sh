#!/bin/bash

# ToDo Manager ECS Deployment Status Checker
# This script checks the status of your ECS deployment

set -e

# Configuration
APPLICATION_NAME="todo-manager"
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
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

# Function to check CloudFormation stack status
check_stack_status() {
    print_status "Checking CloudFormation stack status..."
    
    STACK_STATUS=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $AWS_REGION \
        --query 'Stacks[0].StackStatus' \
        --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$STACK_STATUS" = "NOT_FOUND" ]; then
        print_error "CloudFormation stack not found: $STACK_NAME"
        return 1
    elif [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
        print_success "CloudFormation stack is healthy: $STACK_STATUS"
    else
        print_warning "CloudFormation stack status: $STACK_STATUS"
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
}

# Function to check ECS service status
check_ecs_service() {
    print_status "Checking ECS service status..."
    
    SERVICE_INFO=$(aws ecs describe-services \
        --cluster $ECS_CLUSTER \
        --services $ECS_SERVICE \
        --region $AWS_REGION \
        --query 'services[0]')
    
    RUNNING_COUNT=$(echo $SERVICE_INFO | jq -r '.runningCount')
    DESIRED_COUNT=$(echo $SERVICE_INFO | jq -r '.desiredCount')
    PENDING_COUNT=$(echo $SERVICE_INFO | jq -r '.pendingCount')
    SERVICE_STATUS=$(echo $SERVICE_INFO | jq -r '.status')
    
    echo "Service Status: $SERVICE_STATUS"
    echo "Running Tasks: $RUNNING_COUNT"
    echo "Desired Tasks: $DESIRED_COUNT"
    echo "Pending Tasks: $PENDING_COUNT"
    
    if [ "$RUNNING_COUNT" -eq "$DESIRED_COUNT" ] && [ "$PENDING_COUNT" -eq 0 ]; then
        print_success "ECS service is healthy"
    else
        print_warning "ECS service is not fully healthy"
    fi
}

# Function to check ALB target health
check_alb_targets() {
    print_status "Checking ALB target health..."
    
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
        --names "${APPLICATION_NAME}-${ENVIRONMENT}-tg" \
        --region $AWS_REGION \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text)
    
    if [ "$TARGET_GROUP_ARN" != "None" ]; then
        TARGET_HEALTH=$(aws elbv2 describe-target-health \
            --target-group-arn $TARGET_GROUP_ARN \
            --region $AWS_REGION \
            --query 'TargetHealthDescriptions[*].TargetHealth.State' \
            --output text)
        
        HEALTHY_COUNT=$(echo $TARGET_HEALTH | tr ' ' '\n' | grep -c "healthy" || echo "0")
        TOTAL_COUNT=$(echo $TARGET_HEALTH | wc -w)
        
        echo "Healthy Targets: $HEALTHY_COUNT/$TOTAL_COUNT"
        
        if [ "$HEALTHY_COUNT" -gt 0 ]; then
            print_success "ALB has healthy targets"
        else
            print_warning "ALB has no healthy targets"
        fi
    else
        print_error "Target group not found"
    fi
}

# Function to test application endpoint
test_application() {
    print_status "Testing application endpoint..."
    
    # Test health endpoint
    HEALTH_URL="${ALB_URL}/actuator/health"
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        print_success "Application health check passed"
        
        # Test main application
        MAIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $ALB_URL || echo "000")
        if [ "$MAIN_STATUS" = "200" ]; then
            print_success "Main application endpoint is accessible"
        else
            print_warning "Main application returned HTTP $MAIN_STATUS"
        fi
    else
        print_warning "Health check returned HTTP $HTTP_STATUS"
    fi
}

# Function to show recent logs
show_recent_logs() {
    print_status "Showing recent application logs..."
    
    LOG_GROUP="/ecs/${APPLICATION_NAME}-${ENVIRONMENT}"
    
    # Get the most recent log stream
    LATEST_STREAM=$(aws logs describe-log-streams \
        --log-group-name $LOG_GROUP \
        --region $AWS_REGION \
        --order-by LastEventTime \
        --descending \
        --max-items 1 \
        --query 'logStreams[0].logStreamName' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$LATEST_STREAM" ] && [ "$LATEST_STREAM" != "None" ]; then
        echo "Latest log stream: $LATEST_STREAM"
        echo "Recent logs:"
        echo "============"
        
        aws logs get-log-events \
            --log-group-name $LOG_GROUP \
            --log-stream-name $LATEST_STREAM \
            --region $AWS_REGION \
            --start-time $(date -d '5 minutes ago' +%s)000 \
            --query 'events[*].message' \
            --output text | tail -10
    else
        print_warning "No recent logs found"
    fi
}

# Function to show deployment summary
show_summary() {
    echo ""
    echo "========================================="
    echo "Deployment Summary"
    echo "========================================="
    echo "Application: $APPLICATION_NAME"
    echo "Environment: $ENVIRONMENT"
    echo "Region: $AWS_REGION"
    echo "Stack: $STACK_NAME"
    echo ""
    echo "Application URL: $ALB_URL"
    echo "Health Check: ${ALB_URL}/actuator/health"
    echo ""
    echo "AWS Resources:"
    echo "- ECS Cluster: $ECS_CLUSTER"
    echo "- ECS Service: $ECS_SERVICE"
    echo "- ECR Repository: $ECR_URI"
    echo ""
    echo "Useful Commands:"
    echo "- View logs: aws logs tail $LOG_GROUP --follow"
    echo "- Scale service: aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --desired-count <count>"
    echo "- Force deployment: aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force-new-deployment"
}

# Main execution
main() {
    echo "========================================="
    echo "ToDo Manager ECS Deployment Status"
    echo "========================================="
    echo ""
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is required but not installed. Please install jq first."
        exit 1
    fi
    
    # Check stack status
    if ! check_stack_status; then
        exit 1
    fi
    
    # Get stack outputs
    get_stack_outputs
    
    # Check ECS service
    check_ecs_service
    
    echo ""
    
    # Check ALB targets
    check_alb_targets
    
    echo ""
    
    # Test application
    test_application
    
    echo ""
    
    # Show recent logs
    show_recent_logs
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
