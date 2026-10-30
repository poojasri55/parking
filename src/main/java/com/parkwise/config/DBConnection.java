package com.parkwise.config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public final class DBConnection {

    private static final String URL = System.getenv().getOrDefault(
        "PARKWISE_DB_URL",
        "jdbc:mysql://localhost:3306/parkwise?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
    );

    private static final String USER =
        System.getenv().getOrDefault("PARKWISE_DB_USER", "root");

    private static final String PASSWORD =
        System.getenv().getOrDefault("PARKWISE_DB_PASSWORD", "root");

    private DBConnection() {}

    public static Connection getConnection() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC driver is missing.", e);
        }

        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}