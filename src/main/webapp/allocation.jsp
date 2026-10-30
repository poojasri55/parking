<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="com.parkwise.model.User" %>

<%
    User currentUser = (User) session.getAttribute("user");

    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    List<Map<String, Object>> vehicles =
        (List<Map<String, Object>>) request.getAttribute("vehicles");

    List<Map<String, Object>> slots =
        (List<Map<String, Object>>) request.getAttribute("slots");

    List<Map<String, Object>> allocations =
        (List<Map<String, Object>>) request.getAttribute("allocations");

    if (vehicles == null) vehicles = new ArrayList<>();
    if (slots == null) slots = new ArrayList<>();
    if (allocations == null) allocations = new ArrayList<>();

    String message = request.getParameter("message");
    String errorMsg = request.getParameter("error");
    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Slot Allocation | PARKWISE</title>
    <link rel="stylesheet" href="app-header.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        .form-grid {
            display: grid;
            grid-template-columns: 1fr 1fr auto;
            gap: 1.25rem;
            align-items: flex-end;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .form-group label {
            font-size: 0.85rem;
            font-weight: 600;
            color: var(--text-muted);
            text-transform: uppercase;
        }

        .form-control {
            width: 100%;
            padding: 10px 14px;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            font-size: 0.95rem;
            background: #ffffff;
            outline: none;
            transition: border-color 0.2s;
        }

        .form-control:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(8, 127, 140, 0.15);
        }

        .btn-submit {
            padding: 10px 22px;
            background: var(--primary);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 0.95rem;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            height: 42px;
            transition: background 0.2s;
        }

        .btn-submit:hover {
            background: var(--primary-dark);
        }

        .table-wrap {
            overflow-x: auto;
            border-radius: 10px;
            border: 1px solid var(--border-color);
            margin-top: 1rem;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            background: #ffffff;
            min-width: 650px;
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

        .btn-release {
            background: #fee2e2;
            color: #b91c1c;
            border: none;
            padding: 6px 14px;
            border-radius: 6px;
            font-size: 0.85rem;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: background 0.2s;
        }

        .btn-release:hover {
            background: #fecaca;
        }

        .empty-row {
            text-align: center;
            padding: 30px;
            color: var(--text-muted);
        }

        .callout-info {
            padding: 14px 18px;
            background: #f1f5f9;
            border-radius: 8px;
            color: var(--text-muted);
            font-size: 0.92rem;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        @media (max-width: 768px) {
            .form-grid {
                grid-template-columns: 1fr;
            }
            .btn-submit {
                height: auto;
                justify-content: center;
            }
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
            <li><a href="allocations" class="active"><i class="fa-solid fa-clipboard-check"></i> <span>Bookings</span></a></li>
            <li><a href="monitoring"><i class="fa-solid fa-video"></i> <span>Monitoring</span></a></li>
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
        <h1><i class="fa-solid fa-clipboard-check" style="color: var(--primary);"></i> Parking Slot Allocation</h1>
        <p>Assign an available parking bay to your registered vehicle or release active bookings.</p>
    </div>

    <!-- Feedback Alerts -->
    <% if ("allocated".equals(message)) { %>
        <div class="app-alert app-alert-success">
            <i class="fa-solid fa-circle-check"></i> Parking slot allocated successfully!
        </div>
    <% } else if ("released".equals(message)) { %>
        <div class="app-alert app-alert-success">
            <i class="fa-solid fa-circle-check"></i> Parking slot released successfully!
        </div>
    <% } %>

    <% if (errorMsg != null && !errorMsg.isBlank()) { %>
        <div class="app-alert app-alert-error">
            <i class="fa-solid fa-triangle-exclamation"></i>
            <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(errorMsg) %>
        </div>
    <% } %>

    <!-- Booking Form Card -->
    <div class="app-card">
        <h2 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 1.25rem;">Book a Slot</h2>

        <% if (vehicles.isEmpty()) { %>
            <div class="callout-info">
                <i class="fa-solid fa-circle-info" style="color: var(--primary); font-size: 1.2rem;"></i>
                <span>You do not have any registered vehicles yet. <a href="vehicles" style="color: var(--primary); font-weight:700;">Add a vehicle first</a> to enable slot booking.</span>
            </div>
        <% } else if (slots.isEmpty()) { %>
            <div class="callout-info">
                <i class="fa-solid fa-circle-exclamation" style="color: var(--warning); font-size: 1.2rem;"></i>
                <span>All parking slots are currently occupied. Please check back later or check the <a href="parking-slots" style="color: var(--primary); font-weight:700;">slot directory</a>.</span>
            </div>
        <% } else { %>
            <form method="post" action="<%= request.getContextPath() %>/allocations">
                <input type="hidden" name="action" value="allocate">

                <div class="form-grid">
                    <div class="form-group">
                        <label for="vehicleId">Choose Vehicle</label>
                        <select id="vehicleId" name="vehicleId" class="form-control" required>
                            <option value="">-- Select Your Vehicle --</option>
                            <% for (Map<String, Object> v : vehicles) { %>
                                <option value="<%= v.get("id") %>">
                                    <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(v.get("number"))) %>
                                    (<%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(v.get("type"))) %>)
                                </option>
                            <% } %>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="slotId">Choose Available Slot</label>
                        <select id="slotId" name="slotId" class="form-control" required>
                            <option value="">-- Select Parking Slot --</option>
                            <% for (Map<String, Object> s : slots) { %>
                                <option value="<%= s.get("id") %>">
                                    <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(s.get("number"))) %>
                                    — <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(s.get("floor"))) %>
                                    (<%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(s.get("type"))) %>)
                                </option>
                            <% } %>
                        </select>
                    </div>

                    <button type="submit" class="btn-submit">
                        <i class="fa-solid fa-check"></i> Confirm Booking
                    </button>
                </div>
            </form>
        <% } %>
    </div>

    <!-- Active Allocations List -->
    <div class="app-card">
        <h2 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 1rem;">My Active Bookings (<%= allocations.size() %>)</h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Vehicle Number</th>
                        <th>Type</th>
                        <th>Slot</th>
                        <th>Floor</th>
                        <th>Booking Time</th>
                        <th>Action</th>
                    </tr>
                </thead>

                <tbody>
                <% if (allocations.isEmpty()) { %>
                    <tr>
                        <td colspan="6" class="empty-row">
                            <i class="fa-solid fa-square-parking" style="font-size: 2rem; color: #cbd5e1; display:block; margin-bottom: 8px;"></i>
                            No active parking bookings right now. Use the form above to book a slot.
                        </td>
                    </tr>
                <% } else {
                    for (Map<String, Object> a : allocations) {
                %>
                    <tr>
                        <td><strong><%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(a.get("vehicle"))) %></strong></td>
                        <td><%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(a.get("type"))) %></td>
                        <td><strong style="color: var(--primary);"><%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(a.get("slot"))) %></strong></td>
                        <td><%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(a.get("floor"))) %></td>
                        <td><%= a.get("allocatedAt") == null ? "-" : dateFormat.format(a.get("allocatedAt")) %></td>
                        <td>
                            <form method="post" action="<%= request.getContextPath() %>/allocations" onsubmit="return confirm('Release this parking slot?');" style="margin:0;">
                                <input type="hidden" name="action" value="release">
                                <input type="hidden" name="allocationId" value="<%= a.get("id") %>">
                                <button type="submit" class="btn-release">
                                    <i class="fa-solid fa-arrow-right-from-bracket"></i> Release Slot
                                </button>
                            </form>
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