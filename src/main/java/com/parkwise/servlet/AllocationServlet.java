package com.parkwise.servlet;

import com.parkwise.config.DBConnection;
import com.parkwise.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/allocations")
public class AllocationServlet extends HttpServlet {

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

        List<Map<String, Object>> vehicles = new ArrayList<>();
        List<Map<String, Object>> slots = new ArrayList<>();
        List<Map<String, Object>> allocations = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {
            long userId = findUserId(con, user.getEmail());

            String vehicleSql =
                "SELECT id, registration_number, vehicle_type, vehicle_model "
                + "FROM vehicles WHERE user_id = ? ORDER BY id DESC";

            try (PreparedStatement ps = con.prepareStatement(vehicleSql)) {
                ps.setLong(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> v = new HashMap<>();
                        v.put("id", rs.getLong("id"));
                        v.put("number", rs.getString("registration_number"));
                        v.put("type", rs.getString("vehicle_type"));
                        v.put("model", rs.getString("vehicle_model"));
                        vehicles.add(v);
                    }
                }
            }

            String slotSql =
                "SELECT id, slot_number, floor_name, vehicle_type "
                + "FROM parking_slots WHERE status = 'AVAILABLE' "
                + "ORDER BY slot_number";

            try (PreparedStatement ps = con.prepareStatement(slotSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> s = new HashMap<>();
                    s.put("id", rs.getLong("id"));
                    s.put("number", rs.getString("slot_number"));
                    s.put("floor", rs.getString("floor_name"));
                    s.put("type", rs.getString("vehicle_type"));
                    slots.add(s);
                }
            }

            String allocationSql =
                "SELECT a.id, a.allocated_at, "
                + "COALESCE(a.payment_method, 'COD') AS payment_method, "
                + "COALESCE(a.amount, 100.00) AS amount, "
                + "COALESCE(a.payment_status, 'PENDING (Pay at Gate)') AS payment_status, "
                + "v.registration_number, v.vehicle_type, p.slot_number, p.floor_name "
                + "FROM allocations a "
                + "JOIN vehicles v ON a.vehicle_id = v.id "
                + "JOIN parking_slots p ON a.slot_id = p.id "
                + "WHERE a.user_id = ? AND a.status = 'ACTIVE' "
                + "ORDER BY a.allocated_at DESC";

            try (PreparedStatement ps = con.prepareStatement(allocationSql)) {
                ps.setLong(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> a = new HashMap<>();
                        a.put("id", rs.getLong("id"));
                        a.put("allocatedAt", rs.getTimestamp("allocated_at"));
                        a.put("paymentMethod", rs.getString("payment_method"));
                        a.put("amount", rs.getDouble("amount"));
                        a.put("paymentStatus", rs.getString("payment_status"));
                        a.put("vehicle", rs.getString("registration_number"));
                        a.put("type", rs.getString("vehicle_type"));
                        a.put("slot", rs.getString("slot_number"));
                        a.put("floor", rs.getString("floor_name"));
                        allocations.add(a);
                    }
                }
            }

            request.setAttribute("vehicles", vehicles);
            request.setAttribute("slots", slots);
            request.setAttribute("allocations", allocations);

            request.getRequestDispatcher("/allocation.jsp").forward(request, response);

        } catch (SQLException e) {
            log("Error loading allocations", e);
            response.sendError(500, "Unable to load allocations. Check the database tables.");
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

        try (Connection con = DBConnection.getConnection()) {
            con.setAutoCommit(false);

            try {
                long userId = findUserId(con, user.getEmail());

                if ("allocate".equals(action)) {
                    long vehicleId = parseId(request.getParameter("vehicleId"));
                    long slotId = parseId(request.getParameter("slotId"));

                    // Verify vehicle ownership
                    String vehicleSql = "SELECT vehicle_type FROM vehicles WHERE id = ? AND user_id = ?";
                    String vehicleType;

                    try (PreparedStatement ps = con.prepareStatement(vehicleSql)) {
                        ps.setLong(1, vehicleId);
                        ps.setLong(2, userId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                throw new IllegalArgumentException("Select one of your registered vehicles.");
                            }
                            vehicleType = rs.getString("vehicle_type");
                        }
                    }

                    // Lock and verify slot
                    String slotSql = "SELECT vehicle_type FROM parking_slots WHERE id = ? AND status = 'AVAILABLE' FOR UPDATE";
                    String slotType;

                    try (PreparedStatement ps = con.prepareStatement(slotSql)) {
                        ps.setLong(1, slotId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                throw new IllegalArgumentException("This slot is no longer available. Refresh and try again.");
                            }
                            slotType = rs.getString("vehicle_type");
                        }
                    }

                    if (!vehicleType.equalsIgnoreCase(slotType)) {
                        throw new IllegalArgumentException("The selected slot is for a different vehicle type (" + slotType + ").");
                    }

                    // Check for existing active allocation
                    String activeSql = "SELECT id FROM allocations WHERE vehicle_id = ? AND status = 'ACTIVE' FOR UPDATE";
                    try (PreparedStatement ps = con.prepareStatement(activeSql)) {
                        ps.setLong(1, vehicleId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                throw new IllegalArgumentException("This vehicle already has an active parking allocation.");
                            }
                        }
                    }

                    // Payment Method & Fee Calculation
                    String paymentMethod = request.getParameter("paymentMethod");
                    if (paymentMethod == null || paymentMethod.isBlank()) {
                        paymentMethod = "COD";
                    } else {
                        paymentMethod = paymentMethod.trim().toUpperCase();
                    }

                    double amount;
                    if ("Car".equalsIgnoreCase(vehicleType)) {
                        amount = 100.00;
                    } else if ("Bike".equalsIgnoreCase(vehicleType) || "Scooter".equalsIgnoreCase(vehicleType)) {
                        amount = 40.00;
                    } else if ("Van".equalsIgnoreCase(vehicleType)) {
                        amount = 150.00;
                    } else {
                        amount = 80.00;
                    }

                    String paymentStatus;
                    if ("COD".equalsIgnoreCase(paymentMethod)) {
                        paymentStatus = "PENDING (Pay at Gate)";
                    } else {
                        paymentStatus = "PAID";
                    }

                    String insertSql =
                        "INSERT INTO allocations "
                        + "(user_id, vehicle_id, slot_id, status, payment_method, amount, payment_status) "
                        + "VALUES (?, ?, ?, 'ACTIVE', ?, ?, ?)";

                    try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                        ps.setLong(1, userId);
                        ps.setLong(2, vehicleId);
                        ps.setLong(3, slotId);
                        ps.setString(4, paymentMethod);
                        ps.setDouble(5, amount);
                        ps.setString(6, paymentStatus);
                        ps.executeUpdate();
                    }

                    String updateSlot = "UPDATE parking_slots SET status = 'OCCUPIED' WHERE id = ? AND status = 'AVAILABLE'";
                    try (PreparedStatement ps = con.prepareStatement(updateSlot)) {
                        ps.setLong(1, slotId);
                        if (ps.executeUpdate() != 1) {
                            throw new IllegalArgumentException("The slot could not be reserved.");
                        }
                    }

                } else if ("release".equals(action)) {
                    long allocationId = parseId(request.getParameter("allocationId"));

                    String releaseSql =
                        "SELECT slot_id FROM allocations WHERE id = ? AND user_id = ? AND status = 'ACTIVE' FOR UPDATE";
                    long slotId;

                    try (PreparedStatement ps = con.prepareStatement(releaseSql)) {
                        ps.setLong(1, allocationId);
                        ps.setLong(2, userId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (!rs.next()) {
                                throw new IllegalArgumentException("Active allocation not found.");
                            }
                            slotId = rs.getLong("slot_id");
                        }
                    }

                    try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE allocations SET status = 'RELEASED', released_at = CURRENT_TIMESTAMP "
                        + "WHERE id = ? AND user_id = ? AND status = 'ACTIVE'")) {
                        ps.setLong(1, allocationId);
                        ps.setLong(2, userId);
                        if (ps.executeUpdate() != 1) {
                            throw new IllegalArgumentException("Unable to release this allocation.");
                        }
                    }

                    try (PreparedStatement ps = con.prepareStatement(
                        "UPDATE parking_slots SET status = 'AVAILABLE' WHERE id = ? AND status = 'OCCUPIED'")) {
                        ps.setLong(1, slotId);
                        if (ps.executeUpdate() != 1) {
                            throw new SQLException("Slot status could not be updated.");
                        }
                    }

                } else {
                    throw new IllegalArgumentException("Invalid action.");
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
                }
            }

            response.sendRedirect(
                request.getContextPath() + "/allocations?message="
                + ("allocate".equals(action) ? "allocated" : "released"));

        } catch (IllegalArgumentException e) {
            response.sendRedirect(
                request.getContextPath() + "/allocations?error="
                + java.net.URLEncoder.encode(e.getMessage(), java.nio.charset.StandardCharsets.UTF_8));
        } catch (SQLException e) {
            log("Error processing allocation", e);
            response.sendRedirect(
                request.getContextPath() + "/allocations?error="
                + java.net.URLEncoder.encode("Database error processing request. Please try again.", java.nio.charset.StandardCharsets.UTF_8));
        }
    }

    private long parseId(String value) {
        try {
            long id = Long.parseLong(value);
            if (id <= 0) throw new NumberFormatException();
            return id;
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid vehicle, slot, or allocation ID.");
        }
    }
}
