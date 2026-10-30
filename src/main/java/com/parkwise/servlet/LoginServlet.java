package com.parkwise.servlet;

import com.parkwise.config.DBConnection;
import com.parkwise.model.User;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import org.mindrot.jbcrypt.BCrypt;
import java.io.IOException;
import java.sql.*;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        if (email == null || password == null || email.isBlank() || password.isEmpty()) {
            request.setAttribute("error", "Enter your email and password.");
            request.getRequestDispatcher("/login.jsp").forward(request, response); return;
        }
        String sql = "SELECT id,full_name,email,phone,password_hash,role FROM users WHERE email=?";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email.trim().toLowerCase());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && BCrypt.checkpw(password, rs.getString("password_hash"))) {
                    HttpSession old = request.getSession(false); if (old != null) old.invalidate();
                    HttpSession session = request.getSession(true); session.setMaxInactiveInterval(30 * 60);
                    session.setAttribute("user", new User(rs.getLong("id"), rs.getString("full_name"), rs.getString("email"), rs.getString("phone"), rs.getString("role")));
                    response.sendRedirect(request.getContextPath() + "/dashboard.jsp"); return;
                }
            }
            request.setAttribute("error", "Invalid email or password.");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        } catch (SQLException e) {
            log("Login database error", e); response.setStatus(500);
            request.setAttribute("error", "Unable to connect to the database. Check MySQL configuration.");
            request.getRequestDispatcher("/login.jsp").forward(request, response);
        }
    }
}
