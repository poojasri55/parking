
package com.parkwise.servlet;

import com.parkwise.config.DBConnection;
import com.parkwise.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.util.*;

@WebServlet("/vehicles")
public class VehicleServlet extends HttpServlet {

    private User loggedInUser(HttpServletRequest request) {
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
                throw new SQLException("Logged-in user was not found.");
            }
        }
    }

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        User user = loggedInUser(request);

        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        List<Map<String, Object>> vehicles = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {
            long userId = findUserId(con, user.getEmail());

            String sql = "SELECT id, registration_number, vehicle_type, vehicle_model "
                       + "FROM vehicles WHERE user_id = ? ORDER BY id DESC";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setLong(1, userId);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> v = new HashMap<>();
                        v.put("id", rs.getLong("id"));
                        v.put("registrationNumber",
                              rs.getString("registration_number"));
                        v.put("vehicleType", rs.getString("vehicle_type"));
                        v.put("vehicleModel", rs.getString("vehicle_model"));
                        vehicles.add(v);
                    }
                }
            }

            request.setAttribute("vehicles", vehicles);
            request.getRequestDispatcher("/vehicles.jsp")
                   .forward(request, response);

        } catch (SQLException e) {
            log("Error loading vehicles", e);
            response.sendError(500,
                "Unable to load vehicles. Check the database and vehicles table.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request,
                          HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        User user = loggedInUser(request);
        if (user == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp");
            return;
        }

        String action = request.getParameter("action");

        try (Connection con = DBConnection.getConnection()) {
            long userId = findUserId(con, user.getEmail());

            if ("add".equals(action)) {
                String number = request.getParameter("registrationNumber");
                String type = request.getParameter("vehicleType");
                String model = request.getParameter("vehicleModel");

                if (number == null || number.isBlank()
                        || type == null || type.isBlank()) {
                    response.sendError(400,
                        "Registration number and vehicle type are required.");
                    return;
                }

                number = number.trim().toUpperCase(Locale.ROOT);
                type = type.trim();
                model = model == null ? "" : model.trim();

                if (number.length() > 20 || type.length() > 30
                        || model.length() > 100) {
                    response.sendError(400, "Please shorten the entered details.");
                    return;
                }

                String sql = "INSERT INTO vehicles "
                           + "(user_id, registration_number, vehicle_type, vehicle_model) "
                           + "VALUES (?, ?, ?, ?)";

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setLong(1, userId);
                    ps.setString(2, number);
                    ps.setString(3, type);
                    ps.setString(4, model.isEmpty() ? null : model);
                    ps.executeUpdate();
                }

            } else if ("delete".equals(action)) {
                long vehicleId;

                try {
                    vehicleId = Long.parseLong(request.getParameter("id"));
                    if (vehicleId <= 0) throw new NumberFormatException();
                } catch (Exception e) {
                    response.sendError(400, "Invalid vehicle ID.");
                    return;
                }

                String sql = "DELETE FROM vehicles WHERE id = ? AND user_id = ?";

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setLong(1, vehicleId);
                    ps.setLong(2, userId);
                    ps.executeUpdate();
                }

            } else {
                response.sendError(400, "Invalid vehicle action.");
                return;
            }

            response.sendRedirect(request.getContextPath() + "/vehicles?message=" + action);

        } catch (SQLIntegrityConstraintViolationException e) {
            response.sendRedirect(request.getContextPath() + "/vehicles?error="
                + java.net.URLEncoder.encode("This registration number is already registered.", java.nio.charset.StandardCharsets.UTF_8));
        } catch (SQLException e) {
            log("Error saving vehicle", e);
            response.sendRedirect(request.getContextPath() + "/vehicles?error="
                + java.net.URLEncoder.encode("Database error occurred while updating vehicle.", java.nio.charset.StandardCharsets.UTF_8));
        }
    }
}
