
package com.parkwise.servlet;

import com.parkwise.model.User;
import com.parkwise.config.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/admin")
public class AdminServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        // Step 1: Check whether the user is logged in
        HttpSession session = request.getSession(false);

        User currentUser = session == null
                ? null
                : (User) session.getAttribute("user");

        if (currentUser == null) {
            response.sendRedirect(
                    request.getContextPath() + "/login.jsp");
            return;
        }

        // Step 2: Allow only ADMIN users
        if (!"ADMIN".equalsIgnoreCase(currentUser.getRole())) {
            response.sendError(
                    HttpServletResponse.SC_FORBIDDEN,
                    "Access denied. Administrator access is required.");
            return;
        }

        // Step 3: Prepare a list for registered users
        List<Map<String, Object>> users = new ArrayList<>();

        // Step 4: Connect to MySQL and retrieve users
        try (Connection connection = DBConnection.getConnection()) {

            String sql =
                    "SELECT id, full_name, email, phone, role, created_at "
                  + "FROM users ORDER BY created_at DESC";

            try (PreparedStatement statement =
                         connection.prepareStatement(sql);
                 ResultSet resultSet = statement.executeQuery()) {

                while (resultSet.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();

                    row.put("id", resultSet.getLong("id"));
                    row.put("fullName",
                            resultSet.getString("full_name"));
                    row.put("email",
                            resultSet.getString("email"));
                    row.put("phone",
                            resultSet.getString("phone"));
                    row.put("role",
                            resultSet.getString("role"));
                    row.put("createdAt",
                            resultSet.getTimestamp("created_at"));

                    users.add(row);
                }
            }

            // Step 5: Send user data to admin.jsp
            request.setAttribute("users", users);

            request.getRequestDispatcher("/admin.jsp")
                    .forward(request, response);

        } catch (Exception e) {
            throw new ServletException(
                    "Unable to load administrator dashboard.", e);
        }
    }
}
