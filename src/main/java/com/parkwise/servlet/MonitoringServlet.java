package com.parkwise.servlet;

import com.parkwise.config.DBConnection;
import com.parkwise.model.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/monitoring")
public class MonitoringServlet extends HttpServlet {

    private User getLoggedInUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return null;
        Object value = session.getAttribute("user");
        return value instanceof User ? (User) value : null;
    }

    private long findUserId(Connection con, String email) throws SQLException {
        String sql = "SELECT id FROM users WHERE email = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getLong("id");
            }
        }
        throw new SQLException("Logged-in user not found.");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User user = getLoggedInUser(request);
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        List<Map<String, Object>> records = new ArrayList<>();

        String sql =
            "SELECT a.id AS allocation_id, "
            + "COALESCE(a.payment_method, 'COD') AS payment_method, "
            + "COALESCE(a.amount, 100.00) AS amount, "
            + "COALESCE(a.payment_status, 'PENDING (Pay at Gate)') AS payment_status, "
            + "v.registration_number, v.vehicle_type, "
            + "p.slot_number, p.floor_name, "
            + "m.id AS monitoring_id, m.entry_time, "
            + "m.exit_time, m.status AS monitoring_status, "
            + "a.status AS allocation_status "
            + "FROM allocations a "
            + "JOIN vehicles v ON a.vehicle_id = v.id "
            + "JOIN parking_slots p ON a.slot_id = p.id "
            + "LEFT JOIN monitoring_records m ON m.allocation_id = a.id "
            + "WHERE a.user_id = ? "
            + "ORDER BY a.allocated_at DESC";

        try (Connection con = DBConnection.getConnection()) {

            String countSql =
                "SELECT COUNT(*) AS total_slots, "
                + "COALESCE(SUM(CASE WHEN UPPER(TRIM(status)) = 'OCCUPIED' THEN 1 ELSE 0 END), 0) AS occupied_slots, "
                + "COALESCE(SUM(CASE WHEN UPPER(TRIM(status)) = 'AVAILABLE' THEN 1 ELSE 0 END), 0) AS available_slots "
                + "FROM parking_slots";

            try (PreparedStatement countPs = con.prepareStatement(countSql);
                 ResultSet countRs = countPs.executeQuery()) {
                if (countRs.next()) {
                    request.setAttribute("totalSlots", countRs.getInt("total_slots"));
                    request.setAttribute("occupiedSlots", countRs.getInt("occupied_slots"));
                    request.setAttribute("availableSlots", countRs.getInt("available_slots"));
                }
            }

            long userId = findUserId(con, user.getEmail());

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setLong(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> record = new HashMap<>();
                        record.put("allocationId", rs.getLong("allocation_id"));
                        record.put("paymentMethod", rs.getString("payment_method"));
                        record.put("amount", rs.getDouble("amount"));
                        record.put("paymentStatus", rs.getString("payment_status"));
                        record.put("vehicle", rs.getString("registration_number"));
                        record.put("vehicleType", rs.getString("vehicle_type"));
                        record.put("slot", rs.getString("slot_number"));
                        record.put("floor", rs.getString("floor_name"));
                        record.put("monitoringId", rs.getObject("monitoring_id"));
                        record.put("entryTime", rs.getTimestamp("entry_time"));
                        record.put("exitTime", rs.getTimestamp("exit_time"));
                        record.put("status", rs.getString("monitoring_status"));
                        record.put("allocationStatus", rs.getString("allocation_status"));
                        records.add(record);
                    }
                }
            }

            request.setAttribute("records", records);
            request.getRequestDispatcher("/monitoring.jsp").forward(request, response);

        } catch (SQLException e) {
            log("Error loading monitoring records", e);
            throw new ServletException("Unable to load monitoring data. Check the database tables.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        User user = getLoggedInUser(request);

        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");
        String allocationIdStr = request.getParameter("allocationId");

        if (allocationIdStr == null || allocationIdStr.isBlank()) {
            response.sendRedirect(request.getContextPath() + "/monitoring?error="
                + URLEncoder.encode("Missing allocation reference.", StandardCharsets.UTF_8));
            return;
        }

        long allocationId;
        try {
            allocationId = Long.parseLong(allocationIdStr.trim());
        } catch (NumberFormatException e) {
            response.sendRedirect(request.getContextPath() + "/monitoring?error="
                + URLEncoder.encode("Invalid allocation identifier.", StandardCharsets.UTF_8));
            return;
        }

        try (Connection con = DBConnection.getConnection()) {
            long userId = findUserId(con, user.getEmail());

            String verifySql = "SELECT id FROM allocations WHERE id = ? AND user_id = ?";
            try (PreparedStatement ps = con.prepareStatement(verifySql)) {
                ps.setLong(1, allocationId);
                ps.setLong(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        response.sendRedirect(request.getContextPath() + "/monitoring?error="
                            + URLEncoder.encode("Allocation not found or access denied.", StandardCharsets.UTF_8));
                        return;
                    }
                }
            }

            con.setAutoCommit(false);

            try {
                if ("entry".equalsIgnoreCase(action)) {
                    String checkSql = "SELECT id, status FROM monitoring_records WHERE allocation_id = ?";
                    Long existingId = null;
                    String existingStatus = null;

                    try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                        ps.setLong(1, allocationId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                existingId = rs.getLong("id");
                                existingStatus = rs.getString("status");
                            }
                        }
                    }

                    if (existingId == null) {
                        String insertSql = "INSERT INTO monitoring_records (allocation_id, entry_time, status) VALUES (?, CURRENT_TIMESTAMP, 'INSIDE')";
                        try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                            ps.setLong(1, allocationId);
                            ps.executeUpdate();
                        }
                    } else if ("NOT_ENTERED".equalsIgnoreCase(existingStatus)) {
                        String updateSql = "UPDATE monitoring_records SET entry_time = CURRENT_TIMESTAMP, status = 'INSIDE' WHERE id = ?";
                        try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                            ps.setLong(1, existingId);
                            ps.executeUpdate();
                        }
                    } else {
                        con.rollback();
                        response.sendRedirect(request.getContextPath() + "/monitoring?error="
                            + URLEncoder.encode("Entry has already been recorded for this allocation.", StandardCharsets.UTF_8));
                        return;
                    }

                    // On physical gate entry, mark COD payment as collected!
                    String paySql = "UPDATE allocations SET payment_status = 'PAID (Collected at Gate)' WHERE id = ? AND payment_method = 'COD'";
                    try (PreparedStatement payPs = con.prepareStatement(paySql)) {
                        payPs.setLong(1, allocationId);
                        payPs.executeUpdate();
                    }

                } else if ("exit".equalsIgnoreCase(action)) {
                    String checkSql = "SELECT id, status FROM monitoring_records WHERE allocation_id = ?";
                    Long existingId = null;
                    String existingStatus = null;

                    try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                        ps.setLong(1, allocationId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                existingId = rs.getLong("id");
                                existingStatus = rs.getString("status");
                            }
                        }
                    }

                    if (existingId != null && "INSIDE".equalsIgnoreCase(existingStatus)) {
                        String updateSql = "UPDATE monitoring_records SET exit_time = CURRENT_TIMESTAMP, status = 'EXITED' WHERE id = ?";
                        try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                            ps.setLong(1, existingId);
                            ps.executeUpdate();
                        }
                    } else {
                        con.rollback();
                        response.sendRedirect(request.getContextPath() + "/monitoring?error="
                            + URLEncoder.encode("Vehicle must be parked inside before recording exit.", StandardCharsets.UTF_8));
                        return;
                    }
                } else {
                    con.rollback();
                    response.sendRedirect(request.getContextPath() + "/monitoring?error="
                        + URLEncoder.encode("Unknown monitoring action.", StandardCharsets.UTF_8));
                    return;
                }

                con.commit();

            } catch (SQLException e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }

            response.sendRedirect(request.getContextPath() + "/monitoring?message=" + action.toLowerCase());

        } catch (SQLException e) {
            log("Error processing monitoring action", e);
            response.sendRedirect(request.getContextPath() + "/monitoring?error="
                + URLEncoder.encode("Database error occurred while processing action.", StandardCharsets.UTF_8));
        }
    }
}
