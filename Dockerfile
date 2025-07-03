# Multi-stage build for Spring Boot ToDo Manager
FROM maven:3.8.6-openjdk-11-slim AS build

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies (for better layer caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage
FROM openjdk:11-jre-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r todoapp && useradd -r -g todoapp todoapp

# Set working directory
WORKDIR /app

# Copy the built JAR from build stage
COPY --from=build /app/target/todo-app-*.jar app.jar

# Change ownership to non-root user
RUN chown -R todoapp:todoapp /app
USER todoapp

# Expose port
EXPOSE 8080

# Environment variables with defaults
#ENV SPRING_PROFILES_ACTIVE=dev
ENV SERVER_PORT=8080
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:${SERVER_PORT}/actuator/health || exit 1

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
