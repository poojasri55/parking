package com.parkwise.servlet;

import com.parkwise.config.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import org.mindrot.jbcrypt.BCrypt;
import java.io.IOException;
import java.sql.*;
import java.util.regex.Pattern;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {
    private static final Pattern EMAIL = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");
    private static final Pattern PHONE = Pattern.compile("^[0-9+()\\- ]{7,20}$");

    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        String name = value(request, "fullName");
        String email = value(request, "email").toLowerCase();
        String phone = value(request, "phone");
        String password = request.getParameter("password");
        String confirm = request.getParameter("confirmPassword");

        if (name.length() < 2 || name.length() > 100 || !EMAIL.matcher(email).matches()
                || !PHONE.matcher(phone).matches() || password == null || password.length() < 8 || password.length() > 72
                || confirm == null || !password.equals(confirm)) {
            request.setAttribute("error", "Check your details. Passwords must match and contain 8–72 characters.");
            request.getRequestDispatcher("/register.jsp").forward(request, response); return;
        }

        String sql = "INSERT INTO users(full_name,email,phone,password_hash) VALUES(?,?,?,?)";
        try (Connection conn = DBConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, name); ps.setString(2, email); ps.setString(3, phone); ps.setString(4, BCrypt.hashpw(password, BCrypt.gensalt(12)));
            ps.executeUpdate();
            response.sendRedirect(request.getContextPath() + "/login.jsp?registered=1");
        } catch (SQLIntegrityConstraintViolationException e) {
            request.setAttribute("error", "An account with this email already exists.");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
        } catch (SQLException e) {
            log("Registration database error", e);
            response.setStatus(500); request.setAttribute("error", "Could not create your account. Check the database configuration and try again.");
            request.getRequestDispatcher("/register.jsp").forward(request, response);
        }
    }
    private String value(HttpServletRequest req, String key) { String v = req.getParameter(key); return v == null ? "" : v.trim(); }
}
