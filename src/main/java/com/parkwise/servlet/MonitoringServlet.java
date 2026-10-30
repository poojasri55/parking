
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

        if (session == null) {
            return null;
        }

        Object value = session.getAttribute("user");
        return value instanceof User ? (User) value : null;
    }

    private long findUserId(Connection con, String email)
            throws SQLException {

        String sql = "SELECT id FROM users WHERE email = ?";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong("id");
                }
            }
        }

        throw new SQLException("Logged-in user not found.");
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        User user = getLoggedInUser(request);

        if (user == null) {
            response.sendRedirect(
                request.getContextPath() + "/login.jsp");
            return;
        }

        List<Map<String, Object>> records = new ArrayList<>();

        String sql =
            "SELECT a.id AS allocation_id, "
            + "v.registration_number, v.vehicle_type, "
            + "p.slot_number, p.floor_name, "
            + "m.id AS monitoring_id, m.entry_time, "
            + "m.exit_time, m.status AS monitoring_status, "
            + "a.status AS allocation_status "
            + "FROM allocations a "
            + "JOIN vehicles v ON a.vehicle_id = v.id "
            + "JOIN parking_slots p ON a.slot_id = p.id "
            + "LEFT JOIN monitoring_records m "
            + "ON m.allocation_id = a.id "
            + "WHERE a.user_id = ? "
            + "ORDER BY a.allocated_at DESC";

        try (Connection con = DBConnection.getConnection()) {

            // Read the actual parking capacity and slot statuses.
            String countSql =
                "SELECT COUNT(*) AS total_slots, "
                + "COALESCE(SUM(CASE "
                + "WHEN UPPER(TRIM(status)) = 'OCCUPIED' "
                + "THEN 1 ELSE 0 END), 0) AS occupied_slots, "
                + "COALESCE(SUM(CASE "
                + "WHEN UPPER(TRIM(status)) = 'AVAILABLE' "
                + "THEN 1 ELSE 0 END), 0) AS available_slots "
                + "FROM parking_slots";

            try (PreparedStatement countPs =
                     con.prepareStatement(countSql);
                 ResultSet countRs = countPs.executeQuery()) {

                if (countRs.next()) {
                    request.setAttribute(
                        "totalSlots",
                        countRs.getInt("total_slots"));

                    request.setAttribute(
                        "occupiedSlots",
                        countRs.getInt("occupied_slots"));

                    request.setAttribute(
                        "availableSlots",
                        countRs.getInt("available_slots"));
                }
            }

            // Preserve the existing user-specific monitoring records.
            long userId = findUserId(con, user.getEmail());

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setLong(1, userId);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> record = new HashMap<>();

                        record.put("allocationId",
                            rs.getLong("allocation_id"));
                        record.put("vehicle",
                            rs.getString("registration_number"));
                        record.put("vehicleType",
                            rs.getString("vehicle_type"));
                        record.put("slot",
                            rs.getString("slot_number"));
                        record.put("floor",
                            rs.getString("floor_name"));
                        record.put("monitoringId",
                            rs.getObject("monitoring_id"));
                        record.put("entryTime",
                            rs.getTimestamp("entry_time"));
                        record.put("exitTime",
                            rs.getTimestamp("exit_time"));
                        record.put("status",
                            rs.getString("monitoring_status"));
                        record.put("allocationStatus",
                            rs.getString("allocation_status"));

                        records.add(record);
                    }
                }
            }

            request.setAttribute("records", records);

            request.getRequestDispatcher("/monitoring.jsp")
                   .forward(request, response);

        } catch (SQLException e) {
            log("Error loading monitoring records", e);
            throw new ServletException(
                "Unable to load monitoring data. Check the database tables.",
                e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        User user = getLoggedInUser(request);

        if (user == null) {
            response.sendRedirect(
                request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");

        try (Connection con = DBConnection.getConnection()) {

            long userId = findUserId(con, user.getEmail());
            long allocationId;

            try {
                allocationId = Long.parseLong(
                    request.getParameter("allocationId"));

                if (allocationId <= 0) {
                    throw new NumberFormatException();
                }
            } catch (Exception e) {
                response.sendError(400, "Invalid allocation ID.");
                return;
            }

            con.setAutoCommit(false);

            try {
                String checkSql =
                    "SELECT a.id, a.status AS allocation_status, "
                    + "m.id AS monitoring_id, "
                    + "m.status AS monitoring_status "
                    + "FROM allocations a "
                    + "LEFT JOIN monitoring_records m "
                    + "ON m.allocation_id = a.id "
                    + "WHERE a.id = ? AND a.user_id = ? FOR UPDATE";

                boolean allocationFound = false;
                String allocationStatus = null;
                Long monitoringId = null;
                String monitoringStatus = null;

                try (PreparedStatement ps =
                         con.prepareStatement(checkSql)) {

                    ps.setLong(1, allocationId);
                    ps.setLong(2, userId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            allocationFound = true;
                            allocationStatus =
                                rs.getString("allocation_status");

                            long mid = rs.getLong("monitoring_id");
                            if (!rs.wasNull()) {
                                monitoringId = mid;
                            }

                            monitoringStatus =
                                rs.getString("monitoring_status");
                        }
                    }
                }

                if (!allocationFound) {
                    throw new IllegalArgumentException(
                        "Allocation not found for your account.");
                }

                if (!"ACTIVE".equals(allocationStatus)) {
                    throw new IllegalArgumentException(
                        "This allocation has been released.");
                }

                if ("entry".equals(action)) {

                    if ("INSIDE".equals(monitoringStatus)) {
                        throw new IllegalArgumentException(
                            "Entry has already been recorded.");
                    }

                    if ("EXITED".equals(monitoringStatus)) {
                        throw new IllegalArgumentException(
                            "This allocation already has an exit record.");
                    }

                    if (monitoringId == null) {
                        String insertSql =
                            "INSERT INTO monitoring_records "
                            + "(allocation_id, entry_time, status) "
                            + "VALUES (?, CURRENT_TIMESTAMP, 'INSIDE')";

                        try (PreparedStatement ps =
                                 con.prepareStatement(insertSql)) {
                            ps.setLong(1, allocationId);
                            ps.executeUpdate();
                        }
                    } else {
                        String updateSql =
                            "UPDATE monitoring_records "
                            + "SET entry_time = CURRENT_TIMESTAMP, "
                            + "status = 'INSIDE' "
                            + "WHERE allocation_id = ? "
                            + "AND status = 'NOT_ENTERED'";

                        try (PreparedStatement ps =
                                 con.prepareStatement(updateSql)) {
                            ps.setLong(1, allocationId);

                            if (ps.executeUpdate() != 1) {
                                throw new IllegalArgumentException(
                                    "Unable to record vehicle entry.");
                            }
                        }
                    }

                } else if ("exit".equals(action)) {

                    if (!"INSIDE".equals(monitoringStatus)) {
                        throw new IllegalArgumentException(
                            "Record vehicle entry before recording exit.");
                    }

                    String updateSql =
                        "UPDATE monitoring_records "
                        + "SET exit_time = CURRENT_TIMESTAMP, "
                        + "status = 'EXITED' "
                        + "WHERE allocation_id = ? AND status = 'INSIDE'";

                    try (PreparedStatement ps =
                             con.prepareStatement(updateSql)) {
                        ps.setLong(1, allocationId);

                        if (ps.executeUpdate() != 1) {
                            throw new IllegalArgumentException(
                                "Unable to record vehicle exit.");
                        }
                    }

                } else {
                    throw new IllegalArgumentException(
                        "Invalid monitoring action.");
                }

                con.commit();

            } catch (Exception e) {
                try {
                    con.rollback();
                } catch (SQLException rollbackError) {
                    e.addSuppressed(rollbackError);
                }

                throw e;

            } finally {
                try {
                    con.setAutoCommit(true);
                } catch (SQLException ignored) {
                    // Connection will be closed.
                }
            }

            response.sendRedirect(
                request.getContextPath() + "/monitoring?message="
                + ("entry".equals(action) ? "entry" : "exit"));

        } catch (IllegalArgumentException e) {
            response.sendRedirect(
                request.getContextPath() + "/monitoring?error="
                + URLEncoder.encode(
                    e.getMessage(), StandardCharsets.UTF_8));

        } catch (SQLException e) {
            log("Error recording vehicle entry or exit", e);
            response.sendRedirect(
                request.getContextPath() + "/monitoring?error="
                + URLEncoder.encode(
                    "Database error updating vehicle monitoring.",
                    StandardCharsets.UTF_8));
        }
    }
}
