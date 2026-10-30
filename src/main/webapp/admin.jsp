<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List,java.util.Map" %>
<%@ page import="org.apache.commons.text.StringEscapeUtils" %>
<%@ page import="com.parkwise.model.User" %>

<%
    User currentUser = (User) session.getAttribute("user");

    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    if (!"ADMIN".equalsIgnoreCase(currentUser.getRole())) {
        response.sendError(403, "Administrator access required.");
        return;
    }

    List<Map<String, Object>> users =
        (List<Map<String, Object>>) request.getAttribute("users");
    if (users == null) users = new java.util.ArrayList<>();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Portal | PARKWISE</title>
    <link rel="stylesheet" href="app-header.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        .table-wrap {
            overflow-x: auto;
            border-radius: 10px;
            border: 1px solid var(--border-color);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            background: #ffffff;
            min-width: 700px;
        }

        th, td {
            text-align: left;
            padding: 14px 18px;
            border-bottom: 1px solid var(--border-color);
            font-size: 0.93rem;
        }

        th {
            background: #f8fafc;
            color: var(--text-muted);
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.78rem;
            letter-spacing: 0.5px;
        }

        tr:last-child td {
            border-bottom: none;
        }

        .badge-role {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 700;
        }

        .role-admin {
            background: #fef3c7;
            color: #92400e;
        }

        .role-user {
            background: #e0f2fe;
            color: #0369a1;
        }
    </style>
</head>

<body class="app-layout">

<!-- Standard Fixed Header Navigation -->
<header class="app-header">
    <a href="dashboard.jsp" class="app-brand">
        <i class="fa-solid fa-square-parking"></i>
        <span>PARKWISE</span>
    </a>

    <nav>
        <ul class="app-nav">
            <li><a href="dashboard.jsp"><i class="fa-solid fa-gauge"></i> <span>Dashboard</span></a></li>
            <li><a href="vehicles"><i class="fa-solid fa-car"></i> <span>Vehicles</span></a></li>
            <li><a href="parking-slots"><i class="fa-solid fa-square-parking"></i> <span>Slots</span></a></li>
            <li><a href="allocations"><i class="fa-solid fa-clipboard-check"></i> <span>Bookings</span></a></li>
            <li><a href="monitoring"><i class="fa-solid fa-video"></i> <span>Monitoring</span></a></li>
            <li><a href="admin" class="active"><i class="fa-solid fa-shield-halved"></i> <span>Admin</span></a></li>
            <li>
                <form method="post" action="logout" style="margin:0;">
                    <button type="submit" class="btn-logout" title="Sign out">
                        <i class="fa-solid fa-right-from-bracket"></i> <span>Logout</span>
                    </button>
                </form>
            </li>
        </ul>
    </nav>
</header>

<!-- Main Page Content -->
<main class="app-main">

    <div class="page-title-box">
        <h1><i class="fa-solid fa-shield-halved" style="color: var(--primary);"></i> Administrator Console</h1>
        <p>System oversight, registered user directory, and security management.</p>
    </div>

    <!-- Users Table Card -->
    <div class="app-card">
        <h2 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 1rem;">Registered User Directory (<%= users.size() %>)</h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>User ID</th>
                        <th>Full Name</th>
                        <th>Email Address</th>
                        <th>Phone</th>
                        <th>Role</th>
                        <th>Created At</th>
                    </tr>
                </thead>

                <tbody>
                <% if (users.isEmpty()) { %>
                    <tr>
                        <td colspan="6" style="text-align: center; padding: 25px; color: var(--text-muted);">
                            No registered users found.
                        </td>
                    </tr>
                <% } else {
                    for (Map<String, Object> u : users) {
                        String role = String.valueOf(u.get("role"));
                %>
                    <tr>
                        <td>#<%= u.get("id") %></td>
                        <td><strong><%= StringEscapeUtils.escapeHtml4(String.valueOf(u.get("fullName"))) %></strong></td>
                        <td><%= StringEscapeUtils.escapeHtml4(String.valueOf(u.get("email"))) %></td>
                        <td><%= StringEscapeUtils.escapeHtml4(String.valueOf(u.get("phone"))) %></td>
                        <td>
                            <span class="badge-role <%= "ADMIN".equalsIgnoreCase(role) ? "role-admin" : "role-user" %>">
                                <%= StringEscapeUtils.escapeHtml4(role) %>
                            </span>
                        </td>
                        <td><%= u.get("createdAt") == null ? "-" : u.get("createdAt") %></td>
                    </tr>
                <%  }
                   }
                %>
                </tbody>
            </table>
        </div>
    </div>

</main>

<!-- Unified Footer -->
<footer class="app-footer">
    <p>&copy; 2026 <span>PARKWISE</span> — Smart Vehicle Parking Allocation & Monitoring System. All rights reserved.</p>
</footer>

</body>
</html>
