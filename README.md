# PARKWISE — User Module (Java/JSP/Servlets/MySQL)

This module follows the Zero-Th Review PPT's technology stack. It adds user registration, login, session-protected dashboard, and logout to the existing home page.

## Requirements
- JDK 17 or newer
- Apache Maven 3.9+
- MySQL 8+
- Apache Tomcat 10.1+ (Jakarta Servlet 6)

## Setup
1. Import `database/schema.sql` in MySQL Workbench or phpMyAdmin.
2. Check `src/main/java/com/parkwise/config/DBConnection.java`. Defaults are database `parkwise`, username `root`, and blank password. For another setup, set environment variables `PARKWISE_DB_URL`, `PARKWISE_DB_USER`, and `PARKWISE_DB_PASSWORD`.
3. From this folder run `mvn clean package`.
4. Copy `target/PARKWISE.war` into Tomcat's `webapps` folder and start Tomcat.
5. Open `http://localhost:8080/PARKWISE/`.
6. Select Account & Bookings on the home page, create an account, then sign in.

## Notes
- This is a learning starter; verify it in your local Tomcat/MySQL environment.
- Uses BCrypt password hashing and prepared SQL statements.
- `index.html` is still the existing static homepage; account navigation now opens `login.jsp`.
- Vehicle, parking slot, allocation, monitoring, and admin workflows are intentionally the next modules, not implemented in this User Module.
- To promote a test account to admin after registration: `UPDATE users SET role='ADMIN' WHERE email='your-email@example.com';` The admin module must still implement role-based authorization before using privileged operations.
