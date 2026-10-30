package com.parkwise.config;

import org.mindrot.jbcrypt.BCrypt;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public final class DBConnection {

    private static final String URL = System.getenv().getOrDefault(
        "PARKWISE_DB_URL",
        "jdbc:mysql://localhost:3306/parkwise?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
    );

    private static final String USER =
        System.getenv().getOrDefault("PARKWISE_DB_USER", "root");

    private static final String PASSWORD =
        System.getenv().getOrDefault("PARKWISE_DB_PASSWORD", "root");

    private static volatile boolean initialized = false;

    private DBConnection() {}

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC driver is missing.", e);
        }

        Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);

        if (!initialized) {
            synchronized (DBConnection.class) {
                if (!initialized) {
                    bootstrapDatabase(conn);
                    initialized = true;
                }
            }
        }

        return conn;
    }

    private static void bootstrapDatabase(Connection conn) {
        try (Statement st = conn.createStatement()) {
            // 1. Ensure allocations table has COD payment columns
            try {
                st.executeUpdate("ALTER TABLE allocations ADD COLUMN payment_method VARCHAR(30) NOT NULL DEFAULT 'COD'");
            } catch (SQLException ignored) {
                // Column already exists
            }

            try {
                st.executeUpdate("ALTER TABLE allocations ADD COLUMN amount DECIMAL(10,2) NOT NULL DEFAULT 100.00");
            } catch (SQLException ignored) {
                // Column already exists
            }

            try {
                st.executeUpdate("ALTER TABLE allocations ADD COLUMN payment_status VARCHAR(40) NOT NULL DEFAULT 'PENDING (Pay at Gate)'");
            } catch (SQLException ignored) {
                // Column already exists
            }

            // 2. Ensure Admin User exists: admin@parkwise.com / Admin@123
            try (PreparedStatement checkAdmin = conn.prepareStatement("SELECT id, role FROM users WHERE email = 'admin@parkwise.com'")) {
                try (ResultSet rs = checkAdmin.executeQuery()) {
                    if (!rs.next()) {
                        String adminHash = BCrypt.hashpw("Admin@123", BCrypt.gensalt(12));
                        String insertAdmin = "INSERT INTO users (full_name, email, phone, password_hash, role) VALUES ('System Administrator', 'admin@parkwise.com', '+1-800-PARKWISE', ?, 'ADMIN')";
                        try (PreparedStatement ps = conn.prepareStatement(insertAdmin)) {
                            ps.setString(1, adminHash);
                            ps.executeUpdate();
                        }
                    } else if (!"ADMIN".equalsIgnoreCase(rs.getString("role"))) {
                        try (PreparedStatement updateRole = conn.prepareStatement("UPDATE users SET role = 'ADMIN' WHERE email = 'admin@parkwise.com'")) {
                            updateRole.executeUpdate();
                        }
                    }
                }
            }

            // 3. Ensure seed parking slots exist if table is empty
            try (ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM parking_slots")) {
                if (rs.next() && rs.getInt(1) == 0) {
                    st.executeUpdate(
                        "INSERT IGNORE INTO parking_slots (slot_number, floor_name, vehicle_type, status) VALUES " +
                        "('A-101', 'Ground Floor (Level 0)', 'Car', 'AVAILABLE'), " +
                        "('A-102', 'Ground Floor (Level 0)', 'Car', 'AVAILABLE'), " +
                        "('A-103', 'Ground Floor (Level 0)', 'Car', 'AVAILABLE'), " +
                        "('B-201', '1st Floor (Level 1)', 'Bike', 'AVAILABLE'), " +
                        "('B-202', '1st Floor (Level 1)', 'Bike', 'AVAILABLE'), " +
                        "('B-203', '1st Floor (Level 1)', 'Scooter', 'AVAILABLE'), " +
                        "('C-301', 'Basement (Level -1)', 'Van', 'AVAILABLE'), " +
                        "('EV-101', 'Ground Floor (Level 0)', 'Car', 'AVAILABLE')"
                    );
                }
            }
        } catch (SQLException e) {
            // Log but don't prevent normal connection
            System.err.println("Database bootstrap check: " + e.getMessage());
        }
    }
}
