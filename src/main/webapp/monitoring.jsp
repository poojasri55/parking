<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List,java.util.Map" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="org.apache.commons.text.StringEscapeUtils" %>
<%@ page import="com.parkwise.model.User" %>

<%
    User currentUser = (User) session.getAttribute("user");

    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    List<Map<String, Object>> records =
        (List<Map<String, Object>>) request.getAttribute("records");

    if (records == null) records = new java.util.ArrayList<>();

    String message = request.getParameter("message");
    String mError = request.getParameter("error");
    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM, hh:mm a");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vehicle Monitoring | PARKWISE</title>
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
            min-width: 820px;
        }

        th, td {
            text-align: left;
            padding: 14px 18px;
            border-bottom: 1px solid var(--border-color);
            font-size: 0.93rem;
            vertical-align: middle;
        }

        th {
            background: #f8fafc;
            color: var(--text-muted);
            font-weight: 700;
            text-transform: uppercase;
            font-size: 0.78rem;
            letter-spacing: 0.5px;
        }

        tr:last-child td {
            border-bottom: none;
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.82rem;
            font-weight: 700;
        }

        .status-not-entered {
            background: #f1f5f9;
            color: #64748b;
        }

        .status-inside {
            background: #dcfce7;
            color: #15803d;
        }

        .status-exited {
            background: #e0f2fe;
            color: #0369a1;
        }

        .badge-cod {
            background: #e0f2fe;
            color: #0369a1;
            padding: 3px 8px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 0.78rem;
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .badge-pending {
            background: #fffbeb;
            color: #b45309;
            padding: 3px 8px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 0.78rem;
        }

        .badge-paid {
            background: #ecfdf5;
            color: #047857;
            padding: 3px 8px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 0.78rem;
        }

        .btn-action {
            border: none;
            padding: 7px 14px;
            border-radius: 6px;
            font-size: 0.85rem;
            font-weight: 700;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s;
        }

        .btn-entry {
            background: #dcfce7;
            color: #15803d;
            border: 1px solid #bbf7d0;
        }

        .btn-entry:hover {
            background: #bbf7d0;
        }

        .btn-exit {
            background: #fee2e2;
            color: #b91c1c;
            border: 1px solid #fecaca;
        }

        .btn-exit:hover {
            background: #fecaca;
        }

        .empty-row {
            text-align: center;
            padding: 30px;
            color: var(--text-muted);
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
            <li><a href="index.html"><i class="fa-solid fa-house"></i> <span>Home</span></a></li>
            <li><a href="dashboard.jsp"><i class="fa-solid fa-gauge"></i> <span>Dashboard</span></a></li>
            <li><a href="vehicles"><i class="fa-solid fa-car"></i> <span>Vehicles</span></a></li>
            <li><a href="parking-slots"><i class="fa-solid fa-square-parking"></i> <span>Slots</span></a></li>
            <li><a href="allocations"><i class="fa-solid fa-clipboard-check"></i> <span>Bookings</span></a></li>
            <li><a href="monitoring" class="active"><i class="fa-solid fa-video"></i> <span>Monitoring</span></a></li>
            <% if ("ADMIN".equalsIgnoreCase(currentUser.getRole())) { %>
                <li><a href="admin"><i class="fa-solid fa-shield-halved"></i> <span>Admin</span></a></li>
            <% } %>
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
        <h1><i class="fa-solid fa-video" style="color: var(--primary);"></i> Vehicle Movement Monitoring</h1>
        <p>Record real-time gate entry and exit for active parking allocations with Cash on Delivery status tracking.</p>
    </div>

    <!-- Notifications -->
    <% if ("entry".equals(message)) { %>
        <div class="app-alert app-alert-success">
            <i class="fa-solid fa-circle-check"></i> Vehicle gate entry recorded successfully! Cash on Delivery fee collected at barrier.
        </div>
    <% } else if ("exit".equals(message)) { %>
        <div class="app-alert app-alert-success">
            <i class="fa-solid fa-circle-check"></i> Vehicle exit recorded successfully!
        </div>
    <% } %>

    <% if (mError != null && !mError.isBlank()) { %>
        <div class="app-alert app-alert-error">
            <i class="fa-solid fa-triangle-exclamation"></i>
            <%= StringEscapeUtils.escapeHtml4(mError) %>
        </div>
    <% } %>

    <!-- Monitoring Table -->
    <div class="app-card">
        <h2 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 1rem;">Active Allocations Tracker (<%= records.size() %>)</h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Vehicle</th>
                        <th>Slot</th>
                        <th>Floor</th>
                        <th>Payment Mode</th>
                        <th>Fee Due</th>
                        <th>Entry Timestamp</th>
                        <th>Exit Timestamp</th>
                        <th>Gate Status</th>
                        <th>Action</th>
                    </tr>
                </thead>

                <tbody>
                <% if (records.isEmpty()) { %>
                    <tr>
                        <td colspan="9" class="empty-row">
                            <i class="fa-solid fa-video" style="font-size: 2rem; color: #cbd5e1; display:block; margin-bottom: 8px;"></i>
                            No active vehicle allocations found for monitoring. <a href="allocations" style="color: var(--primary); font-weight:700;">Book a slot</a> first.
                        </td>
                    </tr>
                <% } else {
                    for (Map<String, Object> r : records) {
                        String status = r.get("status") == null ? "NOT_ENTERED" : String.valueOf(r.get("status"));
                        String allocStatus = String.valueOf(r.get("allocationStatus"));
                        String payStatus = r.get("paymentStatus") != null ? String.valueOf(r.get("paymentStatus")) : "PENDING";
                        boolean isPending = payStatus.toUpperCase().contains("PENDING");
                %>
                    <tr>
                        <td><strong><%= StringEscapeUtils.escapeHtml4(String.valueOf(r.get("vehicle"))) %></strong> (<%= StringEscapeUtils.escapeHtml4(String.valueOf(r.get("vehicleType"))) %>)</td>
                        <td><strong style="color: var(--primary);"><%= StringEscapeUtils.escapeHtml4(String.valueOf(r.get("slot"))) %></strong></td>
                        <td><%= StringEscapeUtils.escapeHtml4(String.valueOf(r.get("floor"))) %></td>
                        <td>
                            <span class="badge-cod">
                                <i class="fa-solid fa-money-bill-wave"></i> <%= r.get("paymentMethod") != null ? r.get("paymentMethod") : "COD" %>
                            </span>
                        </td>
                        <td>
                            <strong>₹<%= String.format("%.2f", r.get("amount") != null ? (Double) r.get("amount") : 100.0) %></strong><br>
                            <% if (isPending) { %>
                                <span class="badge-pending" style="font-size: 0.72rem;"><i class="fa-solid fa-clock"></i> <%= payStatus %></span>
                            <% } else { %>
                                <span class="badge-paid" style="font-size: 0.72rem;"><i class="fa-solid fa-circle-check"></i> Paid</span>
                            <% } %>
                        </td>
                        <td><%= r.get("entryTime") == null ? "-" : dateFormat.format(r.get("entryTime")) %></td>
                        <td><%= r.get("exitTime") == null ? "-" : dateFormat.format(r.get("exitTime")) %></td>
                        <td>
                            <% if ("NOT_ENTERED".equals(status)) { %>
                                <span class="status-badge status-not-entered"><i class="fa-solid fa-clock"></i> Not Entered</span>
                            <% } else if ("INSIDE".equals(status)) { %>
                                <span class="status-badge status-inside"><i class="fa-solid fa-car-side"></i> Parked Inside</span>
                            <% } else { %>
                                <span class="status-badge status-exited"><i class="fa-solid fa-check"></i> Exited</span>
                            <% } %>
                        </td>
                        <td>
                            <% if ("ACTIVE".equals(allocStatus)) { %>
                                <% if ("NOT_ENTERED".equals(status)) { %>
                                    <form method="post" action="<%= request.getContextPath() %>/monitoring" style="margin:0;">
                                        <input type="hidden" name="action" value="entry">
                                        <input type="hidden" name="allocationId" value="<%= r.get("allocationId") %>">
                                        <button type="submit" class="btn-action btn-entry" title="Record vehicle entering through gate and collect COD">
                                            <i class="fa-solid fa-door-open"></i> Record Entry (Pay COD)
                                        </button>
                                    </form>
                                <% } else if ("INSIDE".equals(status)) { %>
                                    <form method="post" action="<%= request.getContextPath() %>/monitoring" style="margin:0;">
                                        <input type="hidden" name="action" value="exit">
                                        <input type="hidden" name="allocationId" value="<%= r.get("allocationId") %>">
                                        <button type="submit" class="btn-action btn-exit">
                                            <i class="fa-solid fa-door-closed"></i> Record Exit
                                        </button>
                                    </form>
                                <% } else { %>
                                    <span style="color: var(--text-muted); font-size: 0.85rem;">Completed</span>
                                <% } %>
                            <% } else { %>
                                <span style="color: var(--text-muted); font-size: 0.85rem;">Released</span>
                            <% } %>
                        </td>
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
