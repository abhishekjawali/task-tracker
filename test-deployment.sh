#!/bin/bash

# Test script for Spring Boot ToDo Application deployment
# This script validates the deployment and performs basic functionality tests

set -e

# Configuration
PROJECT_NAME="todo-app"
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
INFRASTRUCTURE_STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-infrastructure"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Function to get ALB URL
get_alb_url() {
    aws cloudformation describe-stacks \
        --stack-name "$INFRASTRUCTURE_STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`ApplicationLoadBalancerURL`].OutputValue' \
        --output text 2>/dev/null || echo ""
}

# Function to test HTTP endpoint
test_endpoint() {
    local url=$1
    local expected_status=$2
    local description=$3
    
    print_status "Testing $description: $url"
    
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 30 || echo "000")
    
    if [[ "$response" == "$expected_status" ]]; then
        print_success "$description - HTTP $response"
        return 0
    else
        print_error "$description - Expected HTTP $expected_status, got HTTP $response"
        return 1
    fi
}

# Function to test JSON endpoint
test_json_endpoint() {
    local url=$1
    local description=$2
    
    print_status "Testing $description: $url"
    
    local response=$(curl -s "$url" --max-time 30 || echo "")
    
    if [[ -n "$response" ]] && echo "$response" | jq . >/dev/null 2>&1; then
        print_success "$description - Valid JSON response"
        echo "Response: $response"
        return 0
    else
        print_error "$description - Invalid or empty JSON response"
        echo "Response: $response"
        return 1
    fi
}

# Main test function
run_tests() {
    print_status "Starting deployment tests..."
    
    # Get ALB URL
    ALB_URL=$(get_alb_url)
    
    if [[ -z "$ALB_URL" ]]; then
        print_error "Could not get ALB URL. Make sure infrastructure is deployed."
        exit 1
    fi
    
    print_status "Testing application at: $ALB_URL"
    
    local test_count=0
    local pass_count=0
    
    # Test 1: Health check endpoint
    ((test_count++))
    if test_json_endpoint "${ALB_URL}/actuator/health" "Health Check Endpoint"; then
        ((pass_count++))
    fi
    
    # Test 2: Main application page
    ((test_count++))
    if test_endpoint "$ALB_URL" "200" "Main Application Page"; then
        ((pass_count++))
    fi
    
    # Test 3: API endpoint - Get all todos
    ((test_count++))
    if test_json_endpoint "${ALB_URL}/api/todos" "Get All Todos API"; then
        ((pass_count++))
    fi
    
    # Test 4: Static resources (CSS)
    ((test_count++))
    if test_endpoint "${ALB_URL}/css/style.css" "200" "Static CSS Resource"; then
        ((pass_count++))
    fi
    
    # Test 5: Static resources (JS)
    ((test_count++))
    if test_endpoint "${ALB_URL}/js/app.js" "200" "Static JS Resource"; then
        ((pass_count++))
    fi
    
    # Test 6: Create a new todo (POST request)
    ((test_count++))
    print_status "Testing Create Todo API"
    local create_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d '{"description":"Test todo from deployment test","priority":"MEDIUM"}' \
        "${ALB_URL}/api/todos" --max-time 30 || echo "")
    
    if [[ -n "$create_response" ]] && echo "$create_response" | jq . >/dev/null 2>&1; then
        print_success "Create Todo API - Valid JSON response"
        echo "Created todo: $create_response"
        ((pass_count++))
        
        # Extract the ID for cleanup
        TODO_ID=$(echo "$create_response" | jq -r '.id' 2>/dev/null || echo "")
    else
        print_error "Create Todo API - Invalid or empty JSON response"
        echo "Response: $create_response"
    fi
    
    # Test 7: Get specific todo (if we created one)
    if [[ -n "$TODO_ID" && "$TODO_ID" != "null" ]]; then
        ((test_count++))
        if test_json_endpoint "${ALB_URL}/api/todos/${TODO_ID}" "Get Specific Todo API"; then
            ((pass_count++))
        fi
        
        # Cleanup: Delete the test todo
        print_status "Cleaning up test todo..."
        curl -s -X DELETE "${ALB_URL}/api/todos/${TODO_ID}" --max-time 30 >/dev/null || true
    fi
    
    # Test 8: Load balancer health check
    ((test_count++))
    print_status "Testing Load Balancer Health Check"
    local health_response=$(curl -s "${ALB_URL}/actuator/health" --max-time 30 || echo "")
    
    if echo "$health_response" | jq -r '.status' 2>/dev/null | grep -q "UP"; then
        print_success "Load Balancer Health Check - Application is UP"
        ((pass_count++))
    else
        print_error "Load Balancer Health Check - Application is not UP"
        echo "Health response: $health_response"
    fi
    
    # Summary
    echo ""
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo "Total Tests: $test_count"
    echo "Passed: $pass_count"
    echo "Failed: $((test_count - pass_count))"
    
    if [[ $pass_count -eq $test_count ]]; then
        print_success "All tests passed! Deployment is successful."
        echo ""
        echo "Application URLs:"
        echo "  Main App: $ALB_URL"
        echo "  Health Check: ${ALB_URL}/actuator/health"
        echo "  API Docs: ${ALB_URL}/api/todos"
        return 0
    else
        print_error "Some tests failed. Please check the deployment."
        return 1
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Test the deployed Spring Boot ToDo Application

OPTIONS:
    --project-name NAME     Project name (default: todo-app)
    --environment ENV       Environment (default: dev)
    --region REGION         AWS region (default: us-east-1)
    --help                  Show this help message

EXAMPLES:
    # Test default deployment
    $0
    
    # Test specific environment
    $0 --environment prod --region us-west-2

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-name)
            PROJECT_NAME="$2"
            INFRASTRUCTURE_STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-infrastructure"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            INFRASTRUCTURE_STACK_NAME="${PROJECT_NAME}-${ENVIRONMENT}-infrastructure"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
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

# Check prerequisites
if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed. Install with: brew install jq"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is required but not installed."
    exit 1
fi

# Run tests
run_tests
