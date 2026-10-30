package com.parkwise.servlet;

import com.parkwise.config.DBConnection;
import com.parkwise.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.mindrot.jbcrypt.BCrypt;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/admin")
public class AdminServlet extends HttpServlet {

    private User getAdminUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return null;
        Object user = session.getAttribute("user");
        if (user instanceof User u && "ADMIN".equalsIgnoreCase(u.getRole())) {
            return u;
        }
        return null;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        User admin = getAdminUser(request);
        if (admin == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=admin_required");
            return;
        }

        List<Map<String, Object>> users = new ArrayList<>();
        List<Map<String, Object>> slots = new ArrayList<>();
        List<Map<String, Object>> bookings = new ArrayList<>();

        int totalUsers = 0;
        int totalSlots = 0;
        int availableSlots = 0;
        int occupiedSlots = 0;
        int maintenanceSlots = 0;
        int activeBookings = 0;
        double totalRevenue = 0.0;
        int codPendingCount = 0;

        try (Connection con = DBConnection.getConnection()) {

            // 1. Fetch Users with vehicle and allocation counts
            String usersSql =
                "SELECT u.id, u.full_name, u.email, u.phone, u.role, u.created_at, " +
                "COUNT(DISTINCT v.id) AS vehicle_count, " +
                "COUNT(DISTINCT a.id) AS booking_count " +
                "FROM users u " +
                "LEFT JOIN vehicles v ON v.user_id = u.id " +
                "LEFT JOIN allocations a ON a.user_id = u.id " +
                "GROUP BY u.id, u.full_name, u.email, u.phone, u.role, u.created_at " +
                "ORDER BY u.id DESC";

            try (PreparedStatement ps = con.prepareStatement(usersSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> u = new HashMap<>();
                    u.put("id", rs.getLong("id"));
                    u.put("fullName", rs.getString("full_name"));
                    u.put("email", rs.getString("email"));
                    u.put("phone", rs.getString("phone"));
                    u.put("role", rs.getString("role"));
                    u.put("createdAt", rs.getTimestamp("created_at"));
                    u.put("vehicleCount", rs.getInt("vehicle_count"));
                    u.put("bookingCount", rs.getInt("booking_count"));
                    users.add(u);
                }
            }
            totalUsers = users.size();

            // 2. Fetch All Parking Slots
            String slotsSql =
                "SELECT id, slot_number, floor_name, vehicle_type, status, created_at " +
                "FROM parking_slots ORDER BY slot_number ASC";

            try (PreparedStatement ps = con.prepareStatement(slotsSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> s = new HashMap<>();
                    String status = rs.getString("status");
                    s.put("id", rs.getLong("id"));
                    s.put("slotNumber", rs.getString("slot_number"));
                    s.put("floorName", rs.getString("floor_name"));
                    s.put("vehicleType", rs.getString("vehicle_type"));
                    s.put("status", status);
                    s.put("createdAt", rs.getTimestamp("created_at"));
                    slots.add(s);

                    totalSlots++;
                    if ("AVAILABLE".equalsIgnoreCase(status)) availableSlots++;
                    else if ("OCCUPIED".equalsIgnoreCase(status)) occupiedSlots++;
                    else if ("MAINTENANCE".equalsIgnoreCase(status)) maintenanceSlots++;
                }
            }

            // 3. Fetch Bookings (Allocations) with COD info
            String bookingsSql =
                "SELECT a.id, a.allocated_at, a.released_at, a.status AS allocation_status, " +
                "COALESCE(a.payment_method, 'COD') AS payment_method, " +
                "COALESCE(a.amount, 100.00) AS amount, " +
                "COALESCE(a.payment_status, 'PENDING (Pay at Gate)') AS payment_status, " +
                "u.full_name AS customer_name, u.email AS customer_email, " +
                "v.registration_number, v.vehicle_type, " +
                "p.id AS slot_id, p.slot_number, p.floor_name " +
                "FROM allocations a " +
                "JOIN users u ON a.user_id = u.id " +
                "JOIN vehicles v ON a.vehicle_id = v.id " +
                "JOIN parking_slots p ON a.slot_id = p.id " +
                "ORDER BY a.allocated_at DESC LIMIT 60";

            try (PreparedStatement ps = con.prepareStatement(bookingsSql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> b = new HashMap<>();
                    String allocStatus = rs.getString("allocation_status");
                    String payStatus = rs.getString("payment_status");
                    double amt = rs.getDouble("amount");

                    b.put("id", rs.getLong("id"));
                    b.put("allocatedAt", rs.getTimestamp("allocated_at"));
                    b.put("releasedAt", rs.getTimestamp("released_at"));
                    b.put("allocationStatus", allocStatus);
                    b.put("paymentMethod", rs.getString("payment_method"));
                    b.put("amount", amt);
                    b.put("paymentStatus", payStatus);
                    b.put("customerName", rs.getString("customer_name"));
                    b.put("customerEmail", rs.getString("customer_email"));
                    b.put("vehicleNumber", rs.getString("registration_number"));
                    b.put("vehicleType", rs.getString("vehicle_type"));
                    b.put("slotId", rs.getLong("slot_id"));
                    b.put("slotNumber", rs.getString("slot_number"));
                    b.put("floorName", rs.getString("floor_name"));
                    bookings.add(b);

                    if ("ACTIVE".equalsIgnoreCase(allocStatus)) {
                        activeBookings++;
                    }
                    totalRevenue += amt;
                    if (payStatus != null && payStatus.toUpperCase().contains("PENDING")) {
                        codPendingCount++;
                    }
                }
            }

            request.setAttribute("users", users);
            request.setAttribute("slots", slots);
            request.setAttribute("bookings", bookings);

            request.setAttribute("totalUsers", totalUsers);
            request.setAttribute("totalSlots", totalSlots);
            request.setAttribute("availableSlots", availableSlots);
            request.setAttribute("occupiedSlots", occupiedSlots);
            request.setAttribute("maintenanceSlots", maintenanceSlots);
            request.setAttribute("activeBookings", activeBookings);
            request.setAttribute("totalRevenue", totalRevenue);
            request.setAttribute("codPendingCount", codPendingCount);

            request.getRequestDispatcher("/admin.jsp").forward(request, response);

        } catch (SQLException e) {
            log("Admin dashboard error", e);
            throw new ServletException("Unable to load administrator dashboard.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        User admin = getAdminUser(request);
        if (admin == null) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "Administrator access required.");
            return;
        }

        String action = request.getParameter("action");
        if (action == null) action = "";

        try (Connection con = DBConnection.getConnection()) {

            switch (action) {
                // ==========================================
                // CUSTOMER (USER) CRUD OPERATIONS
                // ==========================================
                case "addCustomer" -> {
                    String fullName = val(request, "fullName");
                    String email = val(request, "email").toLowerCase();
                    String phone = val(request, "phone");
                    String password = val(request, "password");
                    String role = val(request, "role").toUpperCase();
                    if (!role.equals("ADMIN")) role = "USER";

                    if (fullName.isEmpty() || email.isEmpty() || phone.isEmpty() || password.isEmpty()) {
                        redirectWithError(request, response, "customers", "Please fill in all customer fields.");
                        return;
                    }

                    String checkSql = "SELECT id FROM users WHERE email = ?";
                    try (PreparedStatement checkPs = con.prepareStatement(checkSql)) {
                        checkPs.setString(1, email);
                        try (ResultSet rs = checkPs.executeQuery()) {
                            if (rs.next()) {
                                redirectWithError(request, response, "customers", "A user with this email address already exists.");
                                return;
                            }
                        }
                    }

                    String hash = BCrypt.hashpw(password, BCrypt.gensalt(12));
                    String insertSql = "INSERT INTO users (full_name, email, phone, password_hash, role) VALUES (?, ?, ?, ?, ?)";
                    try (PreparedStatement ps = con.prepareStatement(insertSql)) {
                        ps.setString(1, fullName);
                        ps.setString(2, email);
                        ps.setString(3, phone);
                        ps.setString(4, hash);
                        ps.setString(5, role);
                        ps.executeUpdate();
                    }
                    redirectWithSuccess(request, response, "customers", "Customer account '" + fullName + "' created successfully!");
                }

                case "editCustomer" -> {
                    long userId = Long.parseLong(val(request, "userId"));
                    String fullName = val(request, "fullName");
                    String email = val(request, "email").toLowerCase();
                    String phone = val(request, "phone");
                    String role = val(request, "role").toUpperCase();
                    String newPassword = val(request, "newPassword");
                    if (!role.equals("ADMIN")) role = "USER";

                    // Check if email belongs to someone else
                    String checkSql = "SELECT id FROM users WHERE email = ? AND id != ?";
                    try (PreparedStatement checkPs = con.prepareStatement(checkSql)) {
                        checkPs.setString(1, email);
                        checkPs.setLong(2, userId);
                        try (ResultSet rs = checkPs.executeQuery()) {
                            if (rs.next()) {
                                redirectWithError(request, response, "customers", "Email address is already in use by another user.");
                                return;
                            }
                        }
                    }

                    if (!newPassword.isBlank()) {
                        String hash = BCrypt.hashpw(newPassword, BCrypt.gensalt(12));
                        String updateSql = "UPDATE users SET full_name = ?, email = ?, phone = ?, role = ?, password_hash = ? WHERE id = ?";
                        try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                            ps.setString(1, fullName);
                            ps.setString(2, email);
                            ps.setString(3, phone);
                            ps.setString(4, role);
                            ps.setString(5, hash);
                            ps.setLong(6, userId);
                            ps.executeUpdate();
                        }
                    } else {
                        String updateSql = "UPDATE users SET full_name = ?, email = ?, phone = ?, role = ? WHERE id = ?";
                        try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                            ps.setString(1, fullName);
                            ps.setString(2, email);
                            ps.setString(3, phone);
                            ps.setString(4, role);
                            ps.setLong(5, userId);
                            ps.executeUpdate();
                        }
                    }
                    redirectWithSuccess(request, response, "customers", "Customer details updated successfully!");
                }

                case "deleteCustomer" -> {
                    long userId = Long.parseLong(val(request, "userId"));
                    if (userId == admin.getId()) {
                        redirectWithError(request, response, "customers", "You cannot delete your own logged-in admin account.");
                        return;
                    }

                    String deleteSql = "DELETE FROM users WHERE id = ?";
                    try (PreparedStatement ps = con.prepareStatement(deleteSql)) {
                        ps.setLong(1, userId);
                        ps.executeUpdate();
                    }
                    redirectWithSuccess(request, response, "customers", "Customer account deleted successfully.");
                }

                // ==========================================
                // PARKING SLOT CRUD OPERATIONS
                // ==========================================
                case "addSlot" -> {
                    String slotNumber = val(request, "slotNumber").trim().toUpperCase();
                    String floorName = val(request, "floorName").trim();
                    String vehicleType = val(request, "vehicleType").trim();
                    String status = val(request, "status").trim().toUpperCase();
                    if (!status.equals("OCCUPIED") && !status.equals("MAINTENANCE")) {
                        status = "AVAILABLE";
                    }

                    if (slotNumber.isEmpty() || floorName.isEmpty() || vehicleType.isEmpty()) {
                        redirectWithError(request, response, "slots", "Please provide complete parking slot details.");
                        return;
                    }

                    String checkSlot = "SELECT id FROM parking_slots WHERE slot_number = ?";
                    try (PreparedStatement checkPs = con.prepareStatement(checkSlot)) {
                        checkPs.setString(1, slotNumber);
                        try (ResultSet rs = checkPs.executeQuery()) {
                            if (rs.next()) {
                                redirectWithError(request, response, "slots", "Slot number '" + slotNumber + "' already exists.");
                                return;
                            }
                        }
                    }

                    String insertSlot = "INSERT INTO parking_slots (slot_number, floor_name, vehicle_type, status) VALUES (?, ?, ?, ?)";
                    try (PreparedStatement ps = con.prepareStatement(insertSlot)) {
                        ps.setString(1, slotNumber);
                        ps.setString(2, floorName);
                        ps.setString(3, vehicleType);
                        ps.setString(4, status);
                        ps.executeUpdate();
                    }
                    redirectWithSuccess(request, response, "slots", "Parking slot '" + slotNumber + "' added successfully!");
                }

                case "editSlot" -> {
                    long slotId = Long.parseLong(val(request, "slotId"));
                    String slotNumber = val(request, "slotNumber").trim().toUpperCase();
                    String floorName = val(request, "floorName").trim();
                    String vehicleType = val(request, "vehicleType").trim();
                    String status = val(request, "status").trim().toUpperCase();

                    String updateSlot = "UPDATE parking_slots SET slot_number = ?, floor_name = ?, vehicle_type = ?, status = ? WHERE id = ?";
                    try (PreparedStatement ps = con.prepareStatement(updateSlot)) {
                        ps.setString(1, slotNumber);
                        ps.setString(2, floorName);
                        ps.setString(3, vehicleType);
                        ps.setString(4, status);
                        ps.setLong(5, slotId);
                        ps.executeUpdate();
                    }
                    redirectWithSuccess(request, response, "slots", "Slot '" + slotNumber + "' updated successfully!");
                }

                case "deleteSlot" -> {
                    long slotId = Long.parseLong(val(request, "slotId"));

                    // Check if active allocation exists on this slot
                    String checkAlloc = "SELECT id FROM allocations WHERE slot_id = ? AND status = 'ACTIVE'";
                    try (PreparedStatement ps = con.prepareStatement(checkAlloc)) {
                        ps.setLong(1, slotId);
                        try (ResultSet rs = ps.executeQuery()) {
                            if (rs.next()) {
                                redirectWithError(request, response, "slots", "Cannot delete slot because it has an active vehicle allocation. Release it first.");
                                return;
                            }
                        }
                    }

                    String deleteSlot = "DELETE FROM parking_slots WHERE id = ?";
                    try (PreparedStatement ps = con.prepareStatement(deleteSlot)) {
                        ps.setLong(1, slotId);
                        ps.executeUpdate();
                    }
                    redirectWithSuccess(request, response, "slots", "Parking slot deleted successfully.");
                }

                // ==========================================
                // CASH ON DELIVERY (COD) & BOOKINGS
                // ==========================================
                case "collectPayment" -> {
                    long allocationId = Long.parseLong(val(request, "allocationId"));
                    String updatePay = "UPDATE allocations SET payment_status = 'PAID (Collected at Gate)' WHERE id = ?";
                    try (PreparedStatement ps = con.prepareStatement(updatePay)) {
                        ps.setLong(1, allocationId);
                        ps.executeUpdate();
                    }
                    redirectWithSuccess(request, response, "bookings", "Cash on Delivery (COD) payment marked as collected successfully!");
                }

                case "releaseBookingAdmin" -> {
                    long allocationId = Long.parseLong(val(request, "allocationId"));
                    long slotId = Long.parseLong(val(request, "slotId"));

                    con.setAutoCommit(false);
                    try {
                        String updateAlloc = "UPDATE allocations SET status = 'RELEASED', released_at = CURRENT_TIMESTAMP WHERE id = ?";
                        try (PreparedStatement ps = con.prepareStatement(updateAlloc)) {
                            ps.setLong(1, allocationId);
                            ps.executeUpdate();
                        }

                        String updateSlot = "UPDATE parking_slots SET status = 'AVAILABLE' WHERE id = ?";
                        try (PreparedStatement ps = con.prepareStatement(updateSlot)) {
                            ps.setLong(1, slotId);
                            ps.executeUpdate();
                        }

                        con.commit();
                        redirectWithSuccess(request, response, "bookings", "Booking released and parking slot marked available.");
                    } catch (SQLException e) {
                        con.rollback();
                        throw e;
                    } finally {
                        con.setAutoCommit(true);
                    }
                }

                default -> redirectWithError(request, response, "customers", "Unknown action requested.");
            }

        } catch (Exception e) {
            log("Admin action error", e);
            redirectWithError(request, response, "customers", "Error: " + e.getMessage());
        }
    }

    private String val(HttpServletRequest req, String param) {
        String v = req.getParameter(param);
        return v == null ? "" : v.trim();
    }

    private void redirectWithSuccess(HttpServletRequest req, HttpServletResponse res, String tab, String msg) throws IOException {
        res.sendRedirect(req.getContextPath() + "/admin?tab=" + tab + "&msg=" + URLEncoder.encode(msg, StandardCharsets.UTF_8));
    }

    private void redirectWithError(HttpServletRequest req, HttpServletResponse res, String tab, String err) throws IOException {
        res.sendRedirect(req.getContextPath() + "/admin?tab=" + tab + "&error=" + URLEncoder.encode(err, StandardCharsets.UTF_8));
    }
}
