
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="com.parkwise.model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");

    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    List<Map<String, Object>> slots =
        (List<Map<String, Object>>) request.getAttribute("slots");

    if (slots == null) {
        slots = new ArrayList<>();
    }

    int availableCount = 0;
    int occupiedCount = 0;

    for (Map<String, Object> slot : slots) {
        if ("AVAILABLE".equalsIgnoreCase(
                String.valueOf(slot.get("status")))) {
            availableCount++;
        } else if ("OCCUPIED".equalsIgnoreCase(
                String.valueOf(slot.get("status")))) {
            occupiedCount++;
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Parking Slots | PARKWISE</title>

    <link rel="stylesheet" href="app-header.css">
    <link rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        .slot-summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1.25rem;
            margin-bottom: 2rem;
        }

        .summary-card {
            padding: 1.4rem;
            border-radius: 12px;
            background: #ffffff;
            border: 1px solid var(--border-color);
            box-shadow: var(--shadow-sm);
        }

        .summary-card .label {
            font-size: 0.88rem;
            color: var(--text-muted);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .summary-card strong {
            display: block;
            font-size: 2.2rem;
            margin-top: 8px;
            color: var(--text-main);
        }

        .summary-card strong.available-text {
            color: var(--success);
        }

        .summary-card strong.occupied-text {
            color: var(--danger);
        }

        .table-wrap {
            overflow-x: auto;
            border-radius: 10px;
            border: 1px solid var(--border-color);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            min-width: 600px;
            background: #ffffff;
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

        .badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.82rem;
            font-weight: 700;
        }

        .badge-available {
            background: var(--success-bg);
            color: var(--success);
        }

        .badge-occupied {
            background: var(--danger-bg);
            color: var(--danger);
        }

        .empty-message {
            padding: 30px;
            text-align: center;
            color: var(--text-muted);
        }

        .btn-primary {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            margin-top: 1.5rem;
            padding: 10px 18px;
            background: var(--primary);
            color: white;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 0.92rem;
            transition: background 0.2s;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
        }

        .vehicle-icon {
            color: var(--text-muted);
            margin-right: 4px;
            width: 20px;
            text-align: center;
        }
    </style>
</head>

<body class="app-layout">

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
            <li><a href="parking-slots" class="active"><i class="fa-solid fa-square-parking"></i> <span>Slots</span></a></li>
            <li><a href="allocations"><i class="fa-solid fa-clipboard-check"></i> <span>Bookings</span></a></li>
            <li><a href="monitoring"><i class="fa-solid fa-video"></i> <span>Monitoring</span></a></li>

            <% if ("ADMIN".equalsIgnoreCase(currentUser.getRole())) { %>
                <li><a href="admin"><i class="fa-solid fa-shield-halved"></i> <span>Admin</span></a></li>
            <% } %>

            <li>
                <form method="post" action="logout" style="margin:0;">
                    <button type="submit" class="btn-logout" title="Sign out">
                        <i class="fa-solid fa-right-from-bracket"></i>
                        <span>Logout</span>
                    </button>
                </form>
            </li>
        </ul>
    </nav>
</header>

<main class="app-main">

    <div class="page-title-box">
        <h1>
            <i class="fa-solid fa-square-parking"
               style="color: var(--primary);"></i>
            Parking Slot Availability
        </h1>
        <p>Live view of all parking slots across building levels and current vacancy status.</p>
    </div>

    <div class="slot-summary">
        <div class="summary-card">
            <span class="label">Total Capacity</span>
            <strong><%= slots.size() %></strong>
        </div>

        <div class="summary-card">
            <span class="label">Available Slots</span>
            <strong class="available-text"><%= availableCount %></strong>
        </div>

        <div class="summary-card">
            <span class="label">Occupied Slots</span>
            <strong class="occupied-text"><%= occupiedCount %></strong>
        </div>
    </div>

    <div class="app-card">
        <h2 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 1.25rem;">
            Slot Directory
        </h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Slot Number</th>
                        <th>Floor / Level</th>
                        <th>Allowed Vehicle</th>
                        <th>Current Status</th>
                    </tr>
                </thead>

                <tbody>
                <% if (slots.isEmpty()) { %>
                    <tr>
                        <td colspan="4" class="empty-message">
                            No parking slots found. Please check database configuration.
                        </td>
                    </tr>
                <% } else {
                    for (Map<String, Object> slot : slots) {
                        String status = String.valueOf(slot.get("status"));
                        String vehicleType = String.valueOf(slot.get("vehicleType"));
                        boolean isAvail = "AVAILABLE".equalsIgnoreCase(status);

                        String vehicleIcon;

                        if ("Car".equalsIgnoreCase(vehicleType)) {
                            vehicleIcon = "fa-car";
                        } else if ("Van".equalsIgnoreCase(vehicleType)) {
                            vehicleIcon = "fa-van-shuttle";
                        } else if ("Bike".equalsIgnoreCase(vehicleType)
                                || "Motorcycle".equalsIgnoreCase(vehicleType)) {
                            vehicleIcon = "fa-motorcycle";
                        } else if ("Scooter".equalsIgnoreCase(vehicleType)) {
                            vehicleIcon = "fa-motorcycle";
                        } else {
                            vehicleIcon = "fa-car-side";
                        }
                %>
                    <tr>
                        <td>
                            <strong><%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(
                                String.valueOf(slot.get("slotNumber"))) %></strong>
                        </td>

                        <td>
                            <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(
                                String.valueOf(slot.get("floorName"))) %>
                        </td>

                        <td>
                            <i class="fa-solid <%= vehicleIcon %> vehicle-icon"
                               aria-hidden="true"></i>
                            <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(
                                vehicleType) %>
                        </td>

                        <td>
                            <span class="badge <%= isAvail
                                ? "badge-available" : "badge-occupied" %>">
                                <i class="fa-solid <%= isAvail
                                    ? "fa-circle-check" : "fa-circle-xmark" %>"></i>
                                <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(
                                    status) %>
                            </span>
                        </td>
                    </tr>
                <%  }
                   } %>
                </tbody>
            </table>
        </div>

        <a class="btn-primary"
           href="<%= request.getContextPath() %>/parking-slots">
            <i class="fa-solid fa-arrows-rotate"></i> Refresh Slots
        </a>
    </div>

</main>

<footer class="app-footer">
    <p>&copy; 2026 <span>PARKWISE</span> — Smart Vehicle Parking Allocation &amp; Monitoring System. All rights reserved.</p>
</footer>

</body>
</html>
