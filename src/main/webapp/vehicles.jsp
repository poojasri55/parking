<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="com.parkwise.model.User" %>
<%
    User loggedInUser = (User) session.getAttribute("user");

    if (loggedInUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    List<Map<String, Object>> vehicles =
        (List<Map<String, Object>>) request.getAttribute("vehicles");

    if (vehicles == null) {
        vehicles = new ArrayList<>();
    }

    String message = request.getParameter("message");
    String vError = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>My Vehicles | PARKWISE</title>
    <link rel="stylesheet" href="app-header.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        .form-grid {
            display: grid;
            grid-template-columns: 1.5fr 1.5fr 2fr auto;
            gap: 1rem;
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
            padding: 10px 20px;
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
            min-width: 600px;
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

        .btn-delete {
            background: #fee2e2;
            color: #b91c1c;
            border: none;
            padding: 6px 12px;
            border-radius: 6px;
            font-size: 0.82rem;
            font-weight: 600;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: background 0.2s;
        }

        .btn-delete:hover {
            background: #fecaca;
        }

        .empty-row {
            text-align: center;
            padding: 30px;
            color: var(--text-muted);
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
            <li><a href="index.html"><i class="fa-solid fa-house"></i> <span>Home</span></a></li>
            <li><a href="dashboard.jsp"><i class="fa-solid fa-gauge"></i> <span>Dashboard</span></a></li>
            <li><a href="vehicles" class="active"><i class="fa-solid fa-car"></i> <span>Vehicles</span></a></li>
            <li><a href="parking-slots"><i class="fa-solid fa-square-parking"></i> <span>Slots</span></a></li>
            <li><a href="allocations"><i class="fa-solid fa-clipboard-check"></i> <span>Bookings</span></a></li>
            <li><a href="monitoring"><i class="fa-solid fa-video"></i> <span>Monitoring</span></a></li>
            <% if ("ADMIN".equalsIgnoreCase(loggedInUser.getRole())) { %>
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
        <h1><i class="fa-solid fa-car" style="color: var(--primary);"></i> My Vehicles</h1>
        <p>Register and manage all your personal or commercial vehicles for seamless parking allocation.</p>
    </div>

    <!-- Notification Messages -->
    <% if ("add".equals(message) || "added".equals(message)) { %>
        <div class="app-alert app-alert-success">
            <i class="fa-solid fa-circle-check"></i> Vehicle registered successfully!
        </div>
    <% } else if ("delete".equals(message) || "deleted".equals(message)) { %>
        <div class="app-alert app-alert-success">
            <i class="fa-solid fa-circle-check"></i> Vehicle removed successfully!
        </div>
    <% } %>

    <% if (vError != null && !vError.isBlank()) { %>
        <div class="app-alert app-alert-error">
            <i class="fa-solid fa-triangle-exclamation"></i>
            <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(vError) %>
        </div>
    <% } %>

    <!-- Add Vehicle Card -->
    <div class="app-card">
        <h2 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 1.25rem;">Register New Vehicle</h2>

        <form method="post" action="<%= request.getContextPath() %>/vehicles">
            <input type="hidden" name="action" value="add">

            <div class="form-grid">
                <div class="form-group">
                    <label for="registrationNumber">Plate / Reg Number</label>
                    <input type="text" id="registrationNumber" name="registrationNumber" class="form-control" placeholder="e.g. MH12AB1234" required maxlength="20">
                </div>

                <div class="form-group">
                    <label for="vehicleType">Vehicle Type</label>
                    <select id="vehicleType" name="vehicleType" class="form-control" required>
                        <option value="">Select type...</option>
                        <option value="Car">Car</option>
                        <option value="Bike">Bike / Motorcycle</option>
                        <option value="Scooter">Scooter</option>
                        <option value="Van">Van</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="vehicleModel">Model (Optional)</label>
                    <input type="text" id="vehicleModel" name="vehicleModel" class="form-control" placeholder="e.g. Honda City" maxlength="100">
                </div>

                <button type="submit" class="btn-submit">
                    <i class="fa-solid fa-plus"></i> Add Vehicle
                </button>
            </div>
        </form>
    </div>

    <!-- Vehicles List Card -->
    <div class="app-card">
        <h2 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 1rem;">Registered Vehicles (<%= vehicles.size() %>)</h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Registration Plate</th>
                        <th>Type</th>
                        <th>Model</th>
                        <th>Action</th>
                    </tr>
                </thead>

                <tbody>
                <% if (vehicles.isEmpty()) { %>
                    <tr>
                        <td colspan="4" class="empty-row">
                            <i class="fa-solid fa-car-side" style="font-size: 2rem; color: #cbd5e1; display:block; margin-bottom: 8px;"></i>
                            No vehicles registered yet. Add your first vehicle above to start booking slots.
                        </td>
                    </tr>
                <% } else {
                    for (Map<String, Object> v : vehicles) {
                %>
                    <tr>
                        <td><strong><%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(v.get("registrationNumber"))) %></strong></td>
                        <td>
                            <i class="fa-solid <%= "Car".equalsIgnoreCase(String.valueOf(v.get("vehicleType"))) ? "fa-car" : "fa-motorcycle" %>" style="color: var(--text-muted); margin-right: 4px;"></i>
                            <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(v.get("vehicleType"))) %>
                        </td>
                        <td><%= v.get("vehicleModel") != null ? org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(v.get("vehicleModel"))) : "-" %></td>
                        <td>
                            <form method="post" action="<%= request.getContextPath() %>/vehicles" onsubmit="return confirm('Remove this vehicle?');" style="margin:0;">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="id" value="<%= v.get("id") %>">
                                <button type="submit" class="btn-delete">
                                    <i class="fa-solid fa-trash"></i> Delete
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
