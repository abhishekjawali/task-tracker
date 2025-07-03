# Multi-stage Dockerfile for Spring Boot ToDo Application
# Stage 1: Build stage
FROM maven:3.8.6-openjdk-11-slim AS build

# Set working directory
WORKDIR /app

# Copy pom.xml first to leverage Docker cache
COPY pom.xml .

# Download dependencies (this layer will be cached if pom.xml doesn't change)
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime stage
FROM openjdk:11-jre-slim

# Install curl for health checks
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r todoapp && useradd -r -g todoapp todoapp

# Set working directory
WORKDIR /app

# Copy the built JAR from build stage
COPY --from=build /app/target/todo-app-*.jar app.jar

# Change ownership to non-root user
RUN chown -R todoapp:todoapp /app

# Switch to non-root user
USER todoapp

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Set JVM options for containerized environment
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+UseStringDeduplication"

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
