# ToDo Manager - Spring Boot Web Application

A modern, feature-rich ToDo management application built with Spring Boot, H2/PostgreSQL, and a fancy responsive UI.

## Features

- ✨ **Modern UI**: Beautiful, responsive interface with gradient backgrounds and animations
- 📝 **Complete CRUD Operations**: Create, read, update, and delete todos
- 🔍 **Search & Filter**: Search todos by description, filter by status, priority, and due dates
- 📊 **Priority Management**: Set priority levels (Low, Medium, High, Urgent)
- 👥 **Collaboration**: Add collaborators to todos
- 📅 **Date Management**: Set start and end dates for todos
- 💬 **Comments**: Add additional notes to todos
- 📈 **Statistics Dashboard**: View todo statistics at a glance
- 🎯 **Smart Sorting**: Sort by priority and due dates
- ⚡ **Real-time Updates**: Dynamic UI updates without page refresh
- 📱 **Mobile Responsive**: Works perfectly on all device sizes

## Technology Stack

- **Backend**: Spring Boot 2.7.18 (Java 11)
- **Database**: H2 (Development) / PostgreSQL (Production)
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **UI Framework**: Bootstrap 5.3.0
- **Icons**: Font Awesome 6.4.0
- **Fonts**: Google Fonts (Poppins)
- **Build Tool**: Maven
- **Containerization**: Docker & Docker Compose

## Prerequisites

- Java 11 or higher
- Maven 3.6+
- PostgreSQL 12+ (for production only)
- Docker & Docker Compose (optional, for PostgreSQL setup)

## Quick Start

### Option 1: H2 Database (Recommended for Development)

1. **Clone and navigate to the project**:
   ```bash
   cd /Users/jawalia/Documents/Technical/eks-mcp-app/todo-app3
   ```

2. **Run with H2 database (default)**:
   ```bash
   ./mvnw spring-boot:run
   ```
   
   Or explicitly specify the dev profile:
   ```bash
   ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
   ```

3. **Access the application**:
   - Main application: `http://localhost:8080`
   - H2 Console (for database inspection): `http://localhost:8080/h2-console`
     - JDBC URL: `jdbc:h2:mem:todoapp`
     - Username: `sa`
     - Password: (leave empty)

### Option 2: PostgreSQL Database (Production)

1. **Start PostgreSQL with Docker Compose**:
   ```bash
   docker-compose up -d postgres
   ```

2. **Run with PostgreSQL**:
   ```bash
   ./mvnw spring-boot:run -Dspring-boot.run.profiles=prod
   ```

3. **Access the application**:
   Open your browser and go to `http://localhost:8080`

### Option 3: Full Docker Setup

1. **Build and run everything with Docker Compose**:
   ```bash
   # Uncomment the todo-app service in docker-compose.yml first
   docker-compose up --build
   ```

## Database Configuration

### H2 Database (Development)
- **Profile**: `dev` (default)
- **Type**: In-memory database
- **Auto-initialization**: Yes (schema.sql + data.sql)
- **Sample data**: 15 pre-loaded todos with various states
- **Console access**: `http://localhost:8080/h2-console`

### PostgreSQL Database (Production)
- **Profile**: `prod`
- **Type**: Persistent database
- **Setup**: Manual or Docker Compose
- **Migration**: Hibernate auto-update

## Sample Data

When running with H2 (dev profile), the application automatically loads sample data including:
- 10 regular todos with different priorities and states
- 2 overdue todos for testing
- 3 completed todos
- Various collaborators and comments
- Mixed date ranges for comprehensive testing

## API Endpoints

### Todo CRUD Operations

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/todos` | Get all todos (supports query parameters) |
| GET | `/api/todos/{id}` | Get todo by ID |
| POST | `/api/todos` | Create new todo |
| PUT | `/api/todos/{id}` | Update todo |
| DELETE | `/api/todos/{id}` | Delete todo |
| PATCH | `/api/todos/{id}/toggle` | Toggle completion status |

### Query Parameters for GET /api/todos

- `sort=priority` - Sort by priority and date
- `filter=completed|pending|overdue|due-today|high-priority|urgent` - Filter todos
- `search=<text>` - Search in descriptions

### Specialized Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/todos/priority/{priority}` | Get todos by priority |
| GET | `/api/todos/collaborator/{name}` | Get todos by collaborator |
| GET | `/api/todos/date-range?startDate=&endDate=` | Get todos by date range |

## Database Schema

The application uses a single `todos` table with the following structure:

```sql
CREATE TABLE todos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,  -- H2: AUTO_INCREMENT, PostgreSQL: BIGSERIAL
    description TEXT,
    start_date DATE,
    end_date DATE,
    priority VARCHAR(20) CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    comments TEXT,
    collaborators VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed BOOLEAN DEFAULT FALSE
);
```

## Configuration

### Application Profiles

The application supports multiple profiles:

- **dev** (default): H2 in-memory database with sample data
- **prod**: PostgreSQL database for production

### Profile-specific Properties

**Development (application-dev.properties)**:
```properties
spring.datasource.url=jdbc:h2:mem:todoapp
spring.h2.console.enabled=true
spring.sql.init.mode=always
```

**Production (application.properties)**:
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/todoapp
spring.jpa.hibernate.ddl-auto=update
```

### Environment Variables

You can override configuration using environment variables:

- `SPRING_PROFILES_ACTIVE` - Set active profile
- `SPRING_DATASOURCE_URL` - Database URL
- `SPRING_DATASOURCE_USERNAME` - Database username
- `SPRING_DATASOURCE_PASSWORD` - Database password
- `SERVER_PORT` - Server port

## Development

### Running in Development Mode

```bash
# H2 database (default)
./mvnw spring-boot:run

# PostgreSQL database
./mvnw spring-boot:run -Dspring-boot.run.profiles=prod

# With specific profile
./mvnw spring-boot:run -Dspring.profiles.active=dev
```

### Building for Production

```bash
./mvnw clean package
java -jar target/todo-app-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod
```

### Running Tests

```bash
./mvnw test
```

### Database Console Access

When running with H2 (dev profile):
1. Go to `http://localhost:8080/h2-console`
2. Use connection settings:
   - JDBC URL: `jdbc:h2:mem:todoapp`
   - Username: `sa`
   - Password: (empty)
3. Click "Connect" to access the database

## UI Features

### Create Todo
- Fill out the form on the left panel
- All fields except description are optional
- Click "Add ToDo" to create

### Manage Todos
- View all todos in the right panel
- Use search, filter, and sort controls
- Click action buttons to complete, edit, or delete todos

### Statistics
- View real-time statistics at the top of the todo list
- See total, pending, completed, and overdue counts

### Responsive Design
- Fully responsive layout
- Mobile-friendly interface
- Touch-friendly buttons and controls

## Customization

### Styling
- Modify `src/main/resources/static/css/style.css` for custom styles
- CSS uses CSS custom properties for easy color theming

### JavaScript
- Extend `src/main/resources/static/js/app.js` for additional functionality
- Uses modern ES6+ JavaScript features

### Database Initialization
- Modify `src/main/resources/schema.sql` for schema changes
- Modify `src/main/resources/data.sql` for sample data changes

## Troubleshooting

### Common Issues

1. **H2 Console Not Accessible**:
   - Ensure you're running with `dev` profile
   - Check that `spring.h2.console.enabled=true`
   - Verify URL: `http://localhost:8080/h2-console`

2. **Database Connection Error (PostgreSQL)**:
   - Ensure PostgreSQL is running
   - Check database credentials in application.properties
   - Verify database and user exist

3. **Port Already in Use**:
   - Change server.port in application.properties
   - Or kill the process using port 8080

4. **Build Errors**:
   - Ensure Java 11+ is installed
   - Run `./mvnw clean install` to refresh dependencies

5. **Sample Data Not Loading**:
   - Ensure you're using `dev` profile
   - Check `spring.sql.init.mode=always` in application-dev.properties
   - Verify schema.sql and data.sql are in src/main/resources

### Logs

Application logs are available in the console when running with Maven, or check the logs in your deployment environment.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the API documentation
3. Check application logs
4. Create an issue in the repository

---

**Happy Todo Managing! 🎯**

## API Endpoints

### Todo CRUD Operations

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/todos` | Get all todos (supports query parameters) |
| GET | `/api/todos/{id}` | Get todo by ID |
| POST | `/api/todos` | Create new todo |
| PUT | `/api/todos/{id}` | Update todo |
| DELETE | `/api/todos/{id}` | Delete todo |
| PATCH | `/api/todos/{id}/toggle` | Toggle completion status |

### Query Parameters for GET /api/todos

- `sort=priority` - Sort by priority and date
- `filter=completed|pending|overdue|due-today|high-priority|urgent` - Filter todos
- `search=<text>` - Search in descriptions

### Specialized Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/todos/priority/{priority}` | Get todos by priority |
| GET | `/api/todos/collaborator/{name}` | Get todos by collaborator |
| GET | `/api/todos/date-range?startDate=&endDate=` | Get todos by date range |

## Database Schema

The application uses a single `todos` table with the following structure:

```sql
CREATE TABLE todos (
    id BIGSERIAL PRIMARY KEY,
    description TEXT,
    start_date DATE,
    end_date DATE,
    priority VARCHAR(20) CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    comments TEXT,
    collaborators VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed BOOLEAN DEFAULT FALSE
);
```

## Configuration

### Application Properties

The application can be configured via `src/main/resources/application.properties`:

```properties
# Database Configuration
spring.datasource.url=jdbc:postgresql://localhost:5432/todoapp
spring.datasource.username=todouser
spring.datasource.password=todopass

# JPA Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# Server Configuration
server.port=8080
```

### Environment Variables

You can override configuration using environment variables:

- `SPRING_DATASOURCE_URL`
- `SPRING_DATASOURCE_USERNAME`
- `SPRING_DATASOURCE_PASSWORD`
- `SERVER_PORT`

## Development

### Running in Development Mode

```bash
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

### Building for Production

```bash
./mvnw clean package
java -jar target/todo-app-0.0.1-SNAPSHOT.jar
```

### Running Tests

```bash
./mvnw test
```

## UI Features

### Create Todo
- Fill out the form on the left panel
- All fields except description are optional
- Click "Add ToDo" to create

### Manage Todos
- View all todos in the right panel
- Use search, filter, and sort controls
- Click action buttons to complete, edit, or delete todos

### Statistics
- View real-time statistics at the top of the todo list
- See total, pending, completed, and overdue counts

### Responsive Design
- Fully responsive layout
- Mobile-friendly interface
- Touch-friendly buttons and controls

## Customization

### Styling
- Modify `src/main/resources/static/css/style.css` for custom styles
- CSS uses CSS custom properties for easy color theming

### JavaScript
- Extend `src/main/resources/static/js/app.js` for additional functionality
- Uses modern ES6+ JavaScript features

## Troubleshooting

### Common Issues

1. **Database Connection Error**:
   - Ensure PostgreSQL is running
   - Check database credentials in application.properties
   - Verify database and user exist

2. **Port Already in Use**:
   - Change server.port in application.properties
   - Or kill the process using port 8080

3. **Build Errors**:
   - Ensure Java 11+ is installed
   - Run `./mvnw clean install` to refresh dependencies

### Logs

Application logs are available in the console when running with Maven, or check the logs in your deployment environment.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the API documentation
3. Check application logs
4. Create an issue in the repository

---

**Happy Todo Managing! 🎯**
