<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="org.apache.commons.text.StringEscapeUtils" %>
<%@ page import="com.parkwise.model.User" %>

<%
    User currentUser = (User) session.getAttribute("user");

    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp?error=admin_required");
        return;
    }

    if (!"ADMIN".equalsIgnoreCase(currentUser.getRole())) {
        response.sendError(403, "Administrator access required.");
        return;
    }

    List<Map<String, Object>> users = (List<Map<String, Object>>) request.getAttribute("users");
    List<Map<String, Object>> slots = (List<Map<String, Object>>) request.getAttribute("slots");
    List<Map<String, Object>> bookings = (List<Map<String, Object>>) request.getAttribute("bookings");

    if (users == null) users = new ArrayList<>();
    if (slots == null) slots = new ArrayList<>();
    if (bookings == null) bookings = new ArrayList<>();

    int totalUsers = request.getAttribute("totalUsers") != null ? (Integer) request.getAttribute("totalUsers") : users.size();
    int totalSlots = request.getAttribute("totalSlots") != null ? (Integer) request.getAttribute("totalSlots") : slots.size();
    int availableSlots = request.getAttribute("availableSlots") != null ? (Integer) request.getAttribute("availableSlots") : 0;
    int occupiedSlots = request.getAttribute("occupiedSlots") != null ? (Integer) request.getAttribute("occupiedSlots") : 0;
    int maintenanceSlots = request.getAttribute("maintenanceSlots") != null ? (Integer) request.getAttribute("maintenanceSlots") : 0;
    int activeBookings = request.getAttribute("activeBookings") != null ? (Integer) request.getAttribute("activeBookings") : 0;
    double totalRevenue = request.getAttribute("totalRevenue") != null ? (Double) request.getAttribute("totalRevenue") : 0.0;
    int codPendingCount = request.getAttribute("codPendingCount") != null ? (Integer) request.getAttribute("codPendingCount") : 0;

    String activeTab = request.getParameter("tab");
    if (activeTab == null || activeTab.isBlank()) activeTab = "customers";

    String msg = request.getParameter("msg");
    String error = request.getParameter("error");

    SimpleDateFormat dateFormat = new SimpleDateFormat("dd MMM yyyy, hh:mm a");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Console | PARKWISE</title>
    <link rel="stylesheet" href="app-header.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        /* Admin Navigation Tabs */
        .admin-nav-tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 1.5rem;
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 6px;
            flex-wrap: wrap;
        }

        .admin-tab-btn {
            padding: 10px 20px;
            border-radius: 8px 8px 0 0;
            font-size: 0.95rem;
            font-weight: 700;
            color: var(--text-muted);
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            border-bottom: 3px solid transparent;
            transition: all 0.2s ease;
        }

        .admin-tab-btn:hover {
            color: var(--primary);
            background: rgba(8, 127, 140, 0.05);
        }

        .admin-tab-btn.active {
            color: var(--primary);
            border-bottom-color: var(--primary);
            background: #ffffff;
        }

        .admin-tab-btn .badge-count {
            background: #e2e8f0;
            color: var(--text-main);
            font-size: 0.75rem;
            padding: 2px 8px;
            border-radius: 9999px;
            font-weight: 800;
        }

        .admin-tab-btn.active .badge-count {
            background: var(--primary-light);
            color: var(--primary-dark);
        }

        /* KPI Cards Grid */
        .kpi-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 1.25rem;
            margin-bottom: 2rem;
        }

        .kpi-card {
            background: #ffffff;
            border-radius: 12px;
            padding: 1.25rem 1.5rem;
            border: 1px solid var(--border-color);
            box-shadow: var(--shadow-sm);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .kpi-info h3 {
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.6px;
            color: var(--text-muted);
            margin-bottom: 4px;
        }

        .kpi-info .kpi-num {
            font-size: 1.85rem;
            font-weight: 800;
            color: var(--text-main);
            line-height: 1.1;
        }

        .kpi-info p {
            font-size: 0.78rem;
            color: var(--text-muted);
            margin-top: 4px;
        }

        .kpi-icon {
            width: 50px;
            height: 50px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
        }

        /* Tables & Action Bars */
        .table-action-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
            flex-wrap: wrap;
            gap: 12px;
        }

        .btn-add {
            background: var(--primary);
            color: #ffffff;
            border: none;
            padding: 9px 18px;
            border-radius: 8px;
            font-weight: 700;
            font-size: 0.9rem;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            box-shadow: 0 2px 8px rgba(8, 127, 140, 0.25);
            transition: all 0.2s;
        }

        .btn-add:hover {
            background: var(--primary-dark);
            transform: translateY(-1px);
        }

        .table-wrap {
            overflow-x: auto;
            border-radius: 10px;
            border: 1px solid var(--border-color);
        }

        table {
            width: 100%;
            border-collapse: collapse;
            background: #ffffff;
            min-width: 750px;
        }

        th, td {
            text-align: left;
            padding: 13px 16px;
            border-bottom: 1px solid var(--border-color);
            font-size: 0.92rem;
            vertical-align: middle;
        }

        th {
            background: #f8fafc;
            color: var(--text-muted);
            font-weight: 700;
            text-transform: uppercase;
            font-size: 0.76rem;
            letter-spacing: 0.5px;
        }

        tr:last-child td {
            border-bottom: none;
        }

        /* Badges */
        .badge-role {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.78rem;
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

        .badge-status {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.78rem;
            font-weight: 700;
        }

        .status-available { background: #dcfce7; color: #15803d; }
        .status-occupied { background: #fee2e2; color: #b91c1c; }
        .status-maintenance { background: #fef3c7; color: #b45309; }

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

        /* Action Buttons */
        .btn-action-edit {
            background: #f1f5f9;
            color: var(--text-main);
            border: 1px solid var(--border-color);
            padding: 5px 10px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.8rem;
            font-weight: 600;
            transition: all 0.2s;
        }

        .btn-action-edit:hover {
            background: #e2e8f0;
            color: var(--primary);
        }

        .btn-action-delete {
            background: #fee2e2;
            color: #b91c1c;
            border: 1px solid #fecaca;
            padding: 5px 10px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.8rem;
            font-weight: 600;
            transition: all 0.2s;
        }

        .btn-action-delete:hover {
            background: #fca5a5;
        }

        .btn-action-pay {
            background: #dcfce7;
            color: #166534;
            border: 1px solid #bbf7d0;
            padding: 5px 10px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.8rem;
            font-weight: 700;
        }

        .btn-action-pay:hover {
            background: #bbf7d0;
        }

        /* Modal Styles */
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(4px);
            z-index: 2000;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .modal-overlay.open {
            display: flex;
        }

        .modal-card {
            background: #ffffff;
            border-radius: 14px;
            width: 100%;
            max-width: 500px;
            padding: 24px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2);
            position: relative;
            max-height: 90vh;
            overflow-y: auto;
        }

        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 18px;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 12px;
        }

        .modal-header h3 {
            font-size: 1.2rem;
            color: var(--text-main);
            font-weight: 700;
        }

        .modal-close-btn {
            background: transparent;
            border: none;
            font-size: 1.4rem;
            color: var(--text-muted);
            cursor: pointer;
        }

        .modal-form {
            display: flex;
            flex-direction: column;
            gap: 14px;
        }

        .form-row {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }

        .form-row label {
            font-size: 0.84rem;
            font-weight: 600;
            color: var(--text-muted);
        }

        .form-row input, .form-row select {
            padding: 9px 12px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            font-size: 0.95rem;
            outline: none;
        }

        .form-row input:focus, .form-row select:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(8, 127, 140, 0.15);
        }

        .modal-actions {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            margin-top: 10px;
        }

        .btn-cancel {
            background: #f1f5f9;
            color: var(--text-main);
            border: 1px solid var(--border-color);
            padding: 8px 16px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 600;
        }

        .btn-confirm {
            background: var(--primary);
            color: white;
            border: none;
            padding: 8px 18px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 700;
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
        <h1><i class="fa-solid fa-shield-halved" style="color: var(--primary);"></i> Professional Administrator Console</h1>
        <p>Comprehensive CRUD management for customers, parking slots, allocations, and Cash on Delivery (COD) revenue.</p>
    </div>

    <!-- Alert Notifications -->
    <% if (msg != null && !msg.isBlank()) { %>
        <div class="app-alert app-alert-success">
            <i class="fa-solid fa-circle-check"></i> <%= StringEscapeUtils.escapeHtml4(msg) %>
        </div>
    <% } %>

    <% if (error != null && !error.isBlank()) { %>
        <div class="app-alert app-alert-error">
            <i class="fa-solid fa-triangle-exclamation"></i> <%= StringEscapeUtils.escapeHtml4(error) %>
        </div>
    <% } %>

    <!-- KPI Metric Cards -->
    <div class="kpi-grid">
        <div class="kpi-card">
            <div class="kpi-info">
                <h3>Total Customers</h3>
                <div class="kpi-num"><%= totalUsers %></div>
                <p>Registered Accounts</p>
            </div>
            <div class="kpi-icon" style="background: rgba(14, 165, 233, 0.12); color: #0284c7;">
                <i class="fa-solid fa-users"></i>
            </div>
        </div>

        <div class="kpi-card">
            <div class="kpi-info">
                <h3>Total Parking Slots</h3>
                <div class="kpi-num"><%= totalSlots %></div>
                <p><strong style="color: #16a34a;"><%= availableSlots %></strong> Available &bull; <strong style="color: #dc2626;"><%= occupiedSlots %></strong> Occupied</p>
            </div>
            <div class="kpi-icon" style="background: rgba(16, 185, 129, 0.12); color: #16a34a;">
                <i class="fa-solid fa-square-parking"></i>
            </div>
        </div>

        <div class="kpi-card">
            <div class="kpi-info">
                <h3>Active Bookings</h3>
                <div class="kpi-num"><%= activeBookings %></div>
                <p>Vehicles currently parked</p>
            </div>
            <div class="kpi-icon" style="background: rgba(139, 92, 246, 0.12); color: #7c3aed;">
                <i class="fa-solid fa-clipboard-check"></i>
            </div>
        </div>

        <div class="kpi-card">
            <div class="kpi-info">
                <h3>COD Collections</h3>
                <div class="kpi-num">₹<%= String.format("%.0f", totalRevenue) %></div>
                <p><strong style="color: #d97706;"><%= codPendingCount %></strong> Pending Gate Collections</p>
            </div>
            <div class="kpi-icon" style="background: rgba(245, 158, 11, 0.12); color: #d97706;">
                <i class="fa-solid fa-money-bill-wave"></i>
            </div>
        </div>
    </div>

    <!-- Admin Sub-Navigation Tabs -->
    <nav class="admin-nav-tabs">
        <a href="admin?tab=customers" class="admin-tab-btn <%= "customers".equalsIgnoreCase(activeTab) ? "active" : "" %>">
            <i class="fa-solid fa-users"></i> Customer Management
            <span class="badge-count"><%= users.size() %></span>
        </a>
        <a href="admin?tab=slots" class="admin-tab-btn <%= "slots".equalsIgnoreCase(activeTab) ? "active" : "" %>">
            <i class="fa-solid fa-square-parking"></i> Slot Management
            <span class="badge-count"><%= slots.size() %></span>
        </a>
        <a href="admin?tab=bookings" class="admin-tab-btn <%= "bookings".equalsIgnoreCase(activeTab) ? "active" : "" %>">
            <i class="fa-solid fa-money-bill-wave"></i> Bookings & COD Payments
            <span class="badge-count"><%= bookings.size() %></span>
        </a>
    </nav>

    <!-- ============================================================ -->
    <!-- TAB 1: CUSTOMERS CRUD MANAGEMENT -->
    <!-- ============================================================ -->
    <% if ("customers".equalsIgnoreCase(activeTab)) { %>
    <div class="app-card">
        <div class="table-action-bar">
            <div>
                <h2 style="font-size: 1.25rem; font-weight: 700;">Customer Accounts (<%= users.size() %>)</h2>
                <p style="font-size: 0.85rem; color: var(--text-muted);">Create, inspect, update, or remove customer records.</p>
            </div>
            <button class="btn-add" onclick="openAddCustomerModal()">
                <i class="fa-solid fa-user-plus"></i> Add New Customer
            </button>
        </div>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Full Name</th>
                        <th>Email Address</th>
                        <th>Phone</th>
                        <th>Vehicles</th>
                        <th>Bookings</th>
                        <th>Role</th>
                        <th>Joined Date</th>
                        <th style="text-align: center;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                <% if (users.isEmpty()) { %>
                    <tr><td colspan="9" style="text-align: center; padding: 25px; color: var(--text-muted);">No customers found in database.</td></tr>
                <% } else {
                    for (Map<String, Object> u : users) {
                        String role = String.valueOf(u.get("role"));
                        long uId = (Long) u.get("id");
                %>
                    <tr>
                        <td><strong>#<%= uId %></strong></td>
                        <td><strong><%= StringEscapeUtils.escapeHtml4(String.valueOf(u.get("fullName"))) %></strong></td>
                        <td><%= StringEscapeUtils.escapeHtml4(String.valueOf(u.get("email"))) %></td>
                        <td><%= StringEscapeUtils.escapeHtml4(String.valueOf(u.get("phone"))) %></td>
                        <td><span class="badge-count"><%= u.get("vehicleCount") %></span></td>
                        <td><span class="badge-count"><%= u.get("bookingCount") %></span></td>
                        <td>
                            <span class="badge-role <%= "ADMIN".equalsIgnoreCase(role) ? "role-admin" : "role-user" %>">
                                <%= role %>
                            </span>
                        </td>
                        <td><%= u.get("createdAt") == null ? "-" : dateFormat.format(u.get("createdAt")) %></td>
                        <td style="text-align: center; white-space: nowrap;">
                            <button class="btn-action-edit"
                                    onclick="openEditCustomerModal('<%= uId %>', '<%= StringEscapeUtils.escapeEcmaScript(String.valueOf(u.get("fullName"))) %>', '<%= StringEscapeUtils.escapeEcmaScript(String.valueOf(u.get("email"))) %>', '<%= StringEscapeUtils.escapeEcmaScript(String.valueOf(u.get("phone"))) %>', '<%= StringEscapeUtils.escapeEcmaScript(role) %>')">
                                <i class="fa-solid fa-pen-to-square"></i> Edit
                            </button>
                            <% if (uId != currentUser.getId()) { %>
                                <form method="post" action="admin" style="display: inline;" onsubmit="return confirm('Permanently delete customer <%= StringEscapeUtils.escapeEcmaScript(String.valueOf(u.get("fullName"))) %>? This will delete all their registered vehicles and allocations.');">
                                    <input type="hidden" name="action" value="deleteCustomer">
                                    <input type="hidden" name="userId" value="<%= uId %>">
                                    <button type="submit" class="btn-action-delete"><i class="fa-solid fa-trash"></i> Delete</button>
                                </form>
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
    <% } %>

    <!-- ============================================================ -->
    <!-- TAB 2: PARKING SLOTS CRUD MANAGEMENT -->
    <!-- ============================================================ -->
    <% if ("slots".equalsIgnoreCase(activeTab)) { %>
    <div class="app-card">
        <div class="table-action-bar">
            <div>
                <h2 style="font-size: 1.25rem; font-weight: 700;">Parking Slot Directory (<%= slots.size() %>)</h2>
                <p style="font-size: 0.85rem; color: var(--text-muted);">Manage parking bay numbers, floor levels, vehicle compatibility, and availability status.</p>
            </div>
            <button class="btn-add" onclick="openAddSlotModal()">
                <i class="fa-solid fa-plus-circle"></i> Add New Slot
            </button>
        </div>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Slot ID</th>
                        <th>Slot Number</th>
                        <th>Floor / Level</th>
                        <th>Vehicle Type</th>
                        <th>Status</th>
                        <th>Added Date</th>
                        <th style="text-align: center;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                <% if (slots.isEmpty()) { %>
                    <tr><td colspan="7" style="text-align: center; padding: 25px; color: var(--text-muted);">No parking slots registered.</td></tr>
                <% } else {
                    for (Map<String, Object> s : slots) {
                        String st = String.valueOf(s.get("status"));
                        long sId = (Long) s.get("id");
                %>
                    <tr>
                        <td>#<%= sId %></td>
                        <td><strong style="color: var(--primary); font-size: 1.05rem;"><%= StringEscapeUtils.escapeHtml4(String.valueOf(s.get("slotNumber"))) %></strong></td>
                        <td><%= StringEscapeUtils.escapeHtml4(String.valueOf(s.get("floorName"))) %></td>
                        <td><%= StringEscapeUtils.escapeHtml4(String.valueOf(s.get("vehicleType"))) %></td>
                        <td>
                            <span class="badge-status <%= "AVAILABLE".equalsIgnoreCase(st) ? "status-available" : ("OCCUPIED".equalsIgnoreCase(st) ? "status-occupied" : "status-maintenance") %>">
                                <i class="fa-solid <%= "AVAILABLE".equalsIgnoreCase(st) ? "fa-circle-check" : ("OCCUPIED".equalsIgnoreCase(st) ? "fa-circle-xmark" : "fa-triangle-exclamation") %>"></i>
                                <%= st %>
                            </span>
                        </td>
                        <td><%= s.get("createdAt") == null ? "-" : dateFormat.format(s.get("createdAt")) %></td>
                        <td style="text-align: center; white-space: nowrap;">
                            <button class="btn-action-edit"
                                    onclick="openEditSlotModal('<%= sId %>', '<%= StringEscapeUtils.escapeEcmaScript(String.valueOf(s.get("slotNumber"))) %>', '<%= StringEscapeUtils.escapeEcmaScript(String.valueOf(s.get("floorName"))) %>', '<%= StringEscapeUtils.escapeEcmaScript(String.valueOf(s.get("vehicleType"))) %>', '<%= StringEscapeUtils.escapeEcmaScript(st) %>')">
                                <i class="fa-solid fa-pen-to-square"></i> Edit
                            </button>
                            <form method="post" action="admin" style="display: inline;" onsubmit="return confirm('Delete parking slot <%= StringEscapeUtils.escapeEcmaScript(String.valueOf(s.get("slotNumber"))) %>?');">
                                <input type="hidden" name="action" value="deleteSlot">
                                <input type="hidden" name="slotId" value="<%= sId %>">
                                <button type="submit" class="btn-action-delete"><i class="fa-solid fa-trash"></i> Delete</button>
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
    <% } %>

    <!-- ============================================================ -->
    <!-- TAB 3: BOOKINGS & CASH ON DELIVERY (COD) PAYMENTS -->
    <!-- ============================================================ -->
    <% if ("bookings".equalsIgnoreCase(activeTab)) { %>
    <div class="app-card">
        <div class="table-action-bar">
            <div>
                <h2 style="font-size: 1.25rem; font-weight: 700;">Allocations & Cash on Delivery Tracker (<%= bookings.size() %>)</h2>
                <p style="font-size: 0.85rem; color: var(--text-muted);">Real-time slot allocations, COD gate collection receipts, and release controls.</p>
            </div>
        </div>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Booking ID</th>
                        <th>Customer</th>
                        <th>Vehicle</th>
                        <th>Slot</th>
                        <th>Booking Time</th>
                        <th>Payment Mode</th>
                        <th>Fee Due</th>
                        <th>COD Status</th>
                        <th style="text-align: center;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                <% if (bookings.isEmpty()) { %>
                    <tr><td colspan="9" style="text-align: center; padding: 25px; color: var(--text-muted);">No booking records found.</td></tr>
                <% } else {
                    for (Map<String, Object> b : bookings) {
                        String payStatus = String.valueOf(b.get("paymentStatus"));
                        String allocStatus = String.valueOf(b.get("allocationStatus"));
                        long bId = (Long) b.get("id");
                        long slotId = (Long) b.get("slotId");
                        boolean isPending = payStatus.toUpperCase().contains("PENDING");
                %>
                    <tr>
                        <td><strong>#BK-<%= bId %></strong></td>
                        <td>
                            <strong><%= StringEscapeUtils.escapeHtml4(String.valueOf(b.get("customerName"))) %></strong><br>
                            <span style="font-size: 0.78rem; color: var(--text-muted);"><%= StringEscapeUtils.escapeHtml4(String.valueOf(b.get("customerEmail"))) %></span>
                        </td>
                        <td>
                            <strong><%= StringEscapeUtils.escapeHtml4(String.valueOf(b.get("vehicleNumber"))) %></strong>
                            <span style="font-size: 0.78rem; color: var(--text-muted);">(<%= b.get("vehicleType") %>)</span>
                        </td>
                        <td>
                            <strong style="color: var(--primary);"><%= StringEscapeUtils.escapeHtml4(String.valueOf(b.get("slotNumber"))) %></strong><br>
                            <span style="font-size: 0.75rem; color: var(--text-muted);"><%= b.get("floorName") %></span>
                        </td>
                        <td><%= b.get("allocatedAt") == null ? "-" : dateFormat.format(b.get("allocatedAt")) %></td>
                        <td>
                            <span class="badge-cod">
                                <i class="fa-solid fa-money-bill-wave"></i> <%= b.get("paymentMethod") %>
                            </span>
                        </td>
                        <td><strong>₹<%= String.format("%.2f", (Double) b.get("amount")) %></strong></td>
                        <td>
                            <% if (isPending) { %>
                                <span class="badge-pending"><i class="fa-solid fa-clock"></i> <%= payStatus %></span>
                            <% } else { %>
                                <span class="badge-paid"><i class="fa-solid fa-circle-check"></i> <%= payStatus %></span>
                            <% } %>
                        </td>
                        <td style="text-align: center; white-space: nowrap;">
                            <% if (isPending) { %>
                                <form method="post" action="admin" style="display: inline;">
                                    <input type="hidden" name="action" value="collectPayment">
                                    <input type="hidden" name="allocationId" value="<%= bId %>">
                                    <button type="submit" class="btn-action-pay" title="Collect cash on arrival at gate">
                                        <i class="fa-solid fa-hand-holding-dollar"></i> Collect Cash
                                    </button>
                                </form>
                            <% } %>
                            <% if ("ACTIVE".equalsIgnoreCase(allocStatus)) { %>
                                <form method="post" action="admin" style="display: inline;" onsubmit="return confirm('Release booking #<%= bId %>?');">
                                    <input type="hidden" name="action" value="releaseBookingAdmin">
                                    <input type="hidden" name="allocationId" value="<%= bId %>">
                                    <input type="hidden" name="slotId" value="<%= slotId %>">
                                    <button type="submit" class="btn-action-delete" title="Release occupied slot">
                                        <i class="fa-solid fa-arrow-right-from-bracket"></i> Release
                                    </button>
                                </form>
                            <% } else { %>
                                <span style="font-size: 0.8rem; color: var(--text-muted);"><i class="fa-solid fa-check"></i> Released</span>
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
    <% } %>

</main>

<!-- ============================================================ -->
<!-- MODAL: ADD CUSTOMER -->
<!-- ============================================================ -->
<div id="addCustomerModal" class="modal-overlay">
    <div class="modal-card">
        <div class="modal-header">
            <h3><i class="fa-solid fa-user-plus" style="color: var(--primary);"></i> Add New Customer</h3>
            <button class="modal-close-btn" onclick="closeModal('addCustomerModal')">&times;</button>
        </div>
        <form method="post" action="admin" class="modal-form">
            <input type="hidden" name="action" value="addCustomer">
            <div class="form-row">
                <label for="addFullName">Customer Full Name *</label>
                <input type="text" id="addFullName" name="fullName" required placeholder="e.g. John Doe">
            </div>
            <div class="form-row">
                <label for="addEmail">Email Address *</label>
                <input type="email" id="addEmail" name="email" required placeholder="e.g. john@example.com">
            </div>
            <div class="form-row">
                <label for="addPhone">Phone Number *</label>
                <input type="tel" id="addPhone" name="phone" required placeholder="e.g. +1 555-0199">
            </div>
            <div class="form-row">
                <label for="addPassword">Initial Password *</label>
                <input type="password" id="addPassword" name="password" required minlength="6" placeholder="Minimum 6 characters">
            </div>
            <div class="form-row">
                <label for="addRole">Account Role *</label>
                <select id="addRole" name="role" required>
                    <option value="USER" selected>USER (Standard Customer)</option>
                    <option value="ADMIN">ADMIN (System Administrator)</option>
                </select>
            </div>
            <div class="modal-actions">
                <button type="button" class="btn-cancel" onclick="closeModal('addCustomerModal')">Cancel</button>
                <button type="submit" class="btn-confirm">Create Customer</button>
            </div>
        </form>
    </div>
</div>

<!-- ============================================================ -->
<!-- MODAL: EDIT CUSTOMER -->
<!-- ============================================================ -->
<div id="editCustomerModal" class="modal-overlay">
    <div class="modal-card">
        <div class="modal-header">
            <h3><i class="fa-solid fa-user-pen" style="color: var(--primary);"></i> Edit Customer Details</h3>
            <button class="modal-close-btn" onclick="closeModal('editCustomerModal')">&times;</button>
        </div>
        <form method="post" action="admin" class="modal-form">
            <input type="hidden" name="action" value="editCustomer">
            <input type="hidden" id="editUserId" name="userId">
            <div class="form-row">
                <label for="editFullName">Customer Full Name *</label>
                <input type="text" id="editFullName" name="fullName" required>
            </div>
            <div class="form-row">
                <label for="editEmail">Email Address *</label>
                <input type="email" id="editEmail" name="email" required>
            </div>
            <div class="form-row">
                <label for="editPhone">Phone Number *</label>
                <input type="tel" id="editPhone" name="phone" required>
            </div>
            <div class="form-row">
                <label for="editRole">Account Role *</label>
                <select id="editRole" name="role" required>
                    <option value="USER">USER (Standard Customer)</option>
                    <option value="ADMIN">ADMIN (System Administrator)</option>
                </select>
            </div>
            <div class="form-row">
                <label for="editPassword">New Password (Leave blank to keep existing)</label>
                <input type="password" id="editPassword" name="newPassword" placeholder="Enter new password if changing">
            </div>
            <div class="modal-actions">
                <button type="button" class="btn-cancel" onclick="closeModal('editCustomerModal')">Cancel</button>
                <button type="submit" class="btn-confirm">Save Changes</button>
            </div>
        </form>
    </div>
</div>

<!-- ============================================================ -->
<!-- MODAL: ADD PARKING SLOT -->
<!-- ============================================================ -->
<div id="addSlotModal" class="modal-overlay">
    <div class="modal-card">
        <div class="modal-header">
            <h3><i class="fa-solid fa-square-parking" style="color: var(--primary);"></i> Add New Parking Slot</h3>
            <button class="modal-close-btn" onclick="closeModal('addSlotModal')">&times;</button>
        </div>
        <form method="post" action="admin" class="modal-form">
            <input type="hidden" name="action" value="addSlot">
            <div class="form-row">
                <label for="addSlotNumber">Slot Number / Code *</label>
                <input type="text" id="addSlotNumber" name="slotNumber" required placeholder="e.g. D-401, EV-102">
            </div>
            <div class="form-row">
                <label for="addFloorName">Floor / Level Name *</label>
                <input type="text" id="addFloorName" name="floorName" required placeholder="e.g. Ground Floor, 2nd Floor, Basement">
            </div>
            <div class="form-row">
                <label for="addVehicleType">Vehicle Compatibility *</label>
                <select id="addVehicleType" name="vehicleType" required>
                    <option value="Car" selected>Car (4-Wheeler)</option>
                    <option value="Bike">Bike (2-Wheeler)</option>
                    <option value="Scooter">Scooter (2-Wheeler)</option>
                    <option value="Van">Van / Large Vehicle</option>
                </select>
            </div>
            <div class="form-row">
                <label for="addSlotStatus">Initial Status *</label>
                <select id="addSlotStatus" name="status" required>
                    <option value="AVAILABLE" selected>AVAILABLE</option>
                    <option value="OCCUPIED">OCCUPIED</option>
                    <option value="MAINTENANCE">MAINTENANCE</option>
                </select>
            </div>
            <div class="modal-actions">
                <button type="button" class="btn-cancel" onclick="closeModal('addSlotModal')">Cancel</button>
                <button type="submit" class="btn-confirm">Create Slot</button>
            </div>
        </form>
    </div>
</div>

<!-- ============================================================ -->
<!-- MODAL: EDIT PARKING SLOT -->
<!-- ============================================================ -->
<div id="editSlotModal" class="modal-overlay">
    <div class="modal-card">
        <div class="modal-header">
            <h3><i class="fa-solid fa-pen-to-square" style="color: var(--primary);"></i> Edit Parking Slot</h3>
            <button class="modal-close-btn" onclick="closeModal('editSlotModal')">&times;</button>
        </div>
        <form method="post" action="admin" class="modal-form">
            <input type="hidden" name="action" value="editSlot">
            <input type="hidden" id="editSlotId" name="slotId">
            <div class="form-row">
                <label for="editSlotNumber">Slot Number / Code *</label>
                <input type="text" id="editSlotNumber" name="slotNumber" required>
            </div>
            <div class="form-row">
                <label for="editFloorName">Floor / Level Name *</label>
                <input type="text" id="editFloorName" name="floorName" required>
            </div>
            <div class="form-row">
                <label for="editVehicleType">Vehicle Compatibility *</label>
                <select id="editVehicleType" name="vehicleType" required>
                    <option value="Car">Car (4-Wheeler)</option>
                    <option value="Bike">Bike (2-Wheeler)</option>
                    <option value="Scooter">Scooter (2-Wheeler)</option>
                    <option value="Van">Van / Large Vehicle</option>
                </select>
            </div>
            <div class="form-row">
                <label for="editSlotStatus">Slot Status *</label>
                <select id="editSlotStatus" name="status" required>
                    <option value="AVAILABLE">AVAILABLE</option>
                    <option value="OCCUPIED">OCCUPIED</option>
                    <option value="MAINTENANCE">MAINTENANCE</option>
                </select>
            </div>
            <div class="modal-actions">
                <button type="button" class="btn-cancel" onclick="closeModal('editSlotModal')">Cancel</button>
                <button type="submit" class="btn-confirm">Save Slot</button>
            </div>
        </form>
    </div>
</div>

<!-- Unified Footer -->
<footer class="app-footer">
    <p>&copy; 2026 <span>PARKWISE</span> — Smart Vehicle Parking Allocation & Monitoring System. All rights reserved.</p>
</footer>

<script>
    function closeModal(modalId) {
        document.getElementById(modalId).classList.remove('open');
    }

    function openAddCustomerModal() {
        document.getElementById('addCustomerModal').classList.add('open');
    }

    function openEditCustomerModal(id, name, email, phone, role) {
        document.getElementById('editUserId').value = id;
        document.getElementById('editFullName').value = name;
        document.getElementById('editEmail').value = email;
        document.getElementById('editPhone').value = phone;
        document.getElementById('editRole').value = role;
        document.getElementById('editPassword').value = '';
        document.getElementById('editCustomerModal').classList.add('open');
    }

    function openAddSlotModal() {
        document.getElementById('addSlotModal').classList.add('open');
    }

    function openEditSlotModal(id, slotNumber, floorName, vehicleType, status) {
        document.getElementById('editSlotId').value = id;
        document.getElementById('editSlotNumber').value = slotNumber;
        document.getElementById('editFloorName').value = floorName;
        document.getElementById('editVehicleType').value = vehicleType;
        document.getElementById('editSlotStatus').value = status;
        document.getElementById('editSlotModal').classList.add('open');
    }

    // Close modal when clicking outside modal card
    window.addEventListener('click', function(e) {
        document.querySelectorAll('.modal-overlay').forEach(function(m) {
            if (e.target === m) {
                m.classList.remove('open');
            }
        });
    });
</script>

</body>
</html>
