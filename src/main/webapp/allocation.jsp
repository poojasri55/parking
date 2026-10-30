<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="org.apache.commons.text.StringEscapeUtils" %>
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
            grid-template-columns: 1fr 1fr;
            gap: 1.25rem;
            align-items: flex-start;
        }

        .form-group {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }

        .form-group label {
            font-size: 0.85rem;
            font-weight: 700;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .form-control {
            width: 100%;
            padding: 11px 14px;
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

        /* Payment Method Radio Cards */
        .payment-options-container {
            grid-column: 1 / -1;
            margin-top: 5px;
            margin-bottom: 5px;
            background: #f8fafc;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 16px;
        }

        .payment-options-title {
            font-size: 0.88rem;
            font-weight: 700;
            color: var(--text-main);
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .payment-cards-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 12px;
        }

        .payment-card {
            border: 2px solid var(--border-color);
            border-radius: 8px;
            padding: 12px 14px;
            background: #ffffff;
            display: flex;
            align-items: flex-start;
            gap: 12px;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .payment-card:hover {
            border-color: var(--primary);
        }

        .payment-card input[type="radio"] {
            margin-top: 3px;
            accent-color: var(--primary);
            width: 18px;
            height: 18px;
        }

        .payment-card-body h4 {
            font-size: 0.95rem;
            font-weight: 700;
            color: var(--text-main);
            margin-bottom: 3px;
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .payment-card-body p {
            font-size: 0.82rem;
            color: var(--text-muted);
            line-height: 1.4;
        }

        .payment-card.selected {
            border-color: var(--primary);
            background: rgba(8, 127, 140, 0.04);
        }

        .fee-badge {
            display: inline-block;
            background: #e0f2fe;
            color: #0369a1;
            font-size: 0.75rem;
            font-weight: 800;
            padding: 2px 7px;
            border-radius: 12px;
            margin-left: 6px;
        }

        .btn-submit {
            grid-column: 1 / -1;
            padding: 12px 28px;
            background: var(--primary);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 1rem;
            font-weight: 700;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.2s;
            box-shadow: 0 4px 12px rgba(8, 127, 140, 0.3);
        }

        .btn-submit:hover {
            background: var(--primary-dark);
            transform: translateY(-1px);
        }

        /* Table */
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
            min-width: 800px;
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
            display: inline-flex;
            align-items: center;
            gap: 4px;
        }

        .badge-paid {
            background: #ecfdf5;
            color: #047857;
            padding: 3px 8px;
            border-radius: 6px;
            font-weight: 700;
            font-size: 0.78rem;
        }

        .btn-release {
            background: #fee2e2;
            color: #b91c1c;
            border: 1px solid #fecaca;
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
        <h1><i class="fa-solid fa-clipboard-check" style="color: var(--primary);"></i> Parking Slot Allocation & Booking</h1>
        <p>Book a dedicated parking bay with instant confirmation and <strong>Cash on Delivery (COD / Pay at Gate)</strong>.</p>
    </div>

    <!-- Feedback Alerts -->
    <% if ("allocated".equals(message)) { %>
        <div class="app-alert app-alert-success">
            <i class="fa-solid fa-circle-check"></i> 
            <div>
                <strong>Parking slot allocated successfully!</strong>
                <div style="font-size: 0.88rem; margin-top: 2px;">Your Cash on Delivery (COD) booking is confirmed. Please pay the attendant upon arrival at the parking gate booth.</div>
            </div>
        </div>
    <% } else if ("released".equals(message)) { %>
        <div class="app-alert app-alert-success">
            <i class="fa-solid fa-circle-check"></i> Parking slot released successfully!
        </div>
    <% } %>

    <% if (errorMsg != null && !errorMsg.isBlank()) { %>
        <div class="app-alert app-alert-error">
            <i class="fa-solid fa-triangle-exclamation"></i>
            <%= StringEscapeUtils.escapeHtml4(errorMsg) %>
        </div>
    <% } %>

    <!-- Booking Form Card -->
    <div class="app-card">
        <h2 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 1.25rem;">Book a Parking Slot</h2>

        <% if (vehicles.isEmpty()) { %>
            <div class="callout-info">
                <i class="fa-solid fa-circle-info" style="color: var(--primary); font-size: 1.2rem;"></i>
                <span>You do not have any registered vehicles yet. <a href="vehicles" style="color: var(--primary); font-weight:700;">Add a vehicle first</a> to enable slot booking.</span>
            </div>
        <% } else if (slots.isEmpty()) { %>
            <div class="callout-info">
                <i class="fa-solid fa-circle-exclamation" style="color: var(--warning); font-size: 1.2rem;"></i>
                <span>All parking slots are currently occupied. Please check back later or view the <a href="parking-slots" style="color: var(--primary); font-weight:700;">slot directory</a>.</span>
            </div>
        <% } else { %>
            <form method="post" action="<%= request.getContextPath() %>/allocations">
                <input type="hidden" name="action" value="allocate">

                <div class="form-grid">
                    <div class="form-group">
                        <label for="vehicleId">1. Select Your Registered Vehicle *</label>
                        <select id="vehicleId" name="vehicleId" class="form-control" required>
                            <option value="">-- Choose Vehicle --</option>
                            <% for (Map<String, Object> v : vehicles) { %>
                                <option value="<%= v.get("id") %>">
                                    <%= StringEscapeUtils.escapeHtml4(String.valueOf(v.get("number"))) %>
                                    — <%= StringEscapeUtils.escapeHtml4(String.valueOf(v.get("type"))) %>
                                    <% if (v.get("model") != null && !String.valueOf(v.get("model")).isBlank()) { %>
                                        (<%= StringEscapeUtils.escapeHtml4(String.valueOf(v.get("model"))) %>)
                                    <% } %>
                                </option>
                            <% } %>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="slotId">2. Choose Available Parking Bay *</label>
                        <select id="slotId" name="slotId" class="form-control" required>
                            <option value="">-- Choose Parking Slot --</option>
                            <% for (Map<String, Object> s : slots) { %>
                                <option value="<%= s.get("id") %>">
                                    Slot <%= StringEscapeUtils.escapeHtml4(String.valueOf(s.get("number"))) %>
                                    — <%= StringEscapeUtils.escapeHtml4(String.valueOf(s.get("floor"))) %>
                                    [<%= StringEscapeUtils.escapeHtml4(String.valueOf(s.get("type"))) %> compatible]
                                </option>
                            <% } %>
                        </select>
                    </div>

                    <!-- Payment Method Section (Cash on Delivery) -->
                    <div class="payment-options-container">
                        <div class="payment-options-title">
                            <i class="fa-solid fa-wallet" style="color: var(--primary);"></i>
                            <span>3. Select Payment Method & Parking Fee</span>
                        </div>

                        <div class="payment-cards-grid">
                            <label class="payment-card selected" id="cardCod">
                                <input type="radio" name="paymentMethod" value="COD" checked>
                                <div class="payment-card-body">
                                    <h4>
                                        <i class="fa-solid fa-money-bill-wave" style="color: #16a34a;"></i>
                                        Cash on Delivery (Pay at Gate)
                                        <span class="fee-badge">Recommended</span>
                                    </h4>
                                    <p>No credit card or online payment required. Pay cash directly to the gate attendant upon physical drive-in.</p>
                                </div>
                            </label>

                            <label class="payment-card" id="cardOnline">
                                <input type="radio" name="paymentMethod" value="ONLINE">
                                <div class="payment-card-body">
                                    <h4>
                                        <i class="fa-solid fa-credit-card" style="color: var(--primary);"></i>
                                        Online / UPI Simulation
                                    </h4>
                                    <p>Fast digital pass. Marked as pre-paid instantly for touchless barrier pass.</p>
                                </div>
                            </label>
                        </div>

                        <div style="margin-top: 10px; font-size: 0.8rem; color: var(--text-muted); display: flex; align-items: center; gap: 6px;">
                            <i class="fa-solid fa-circle-info" style="color: var(--primary);"></i>
                            <span>Standard Parking Rates: <strong>Car ₹100</strong> &bull; <strong>Bike / Scooter ₹40</strong> &bull; <strong>Van ₹150</strong> (flat fee for session).</span>
                        </div>
                    </div>

                    <button type="submit" class="btn-submit">
                        <i class="fa-solid fa-check"></i> Confirm Slot Reservation (COD / Pay at Gate)
                    </button>
                </div>
            </form>
        <% } %>
    </div>

    <!-- Active Allocations List -->
    <div class="app-card">
        <h2 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 1rem;">My Active Parking Bookings (<%= allocations.size() %>)</h2>

        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Vehicle Number</th>
                        <th>Type</th>
                        <th>Assigned Slot</th>
                        <th>Floor Level</th>
                        <th>Booking Time</th>
                        <th>Payment Mode</th>
                        <th>Fee Due</th>
                        <th>Payment Status</th>
                        <th>Action</th>
                    </tr>
                </thead>

                <tbody>
                <% if (allocations.isEmpty()) { %>
                    <tr>
                        <td colspan="9" class="empty-row">
                            <i class="fa-solid fa-square-parking" style="font-size: 2rem; color: #cbd5e1; display:block; margin-bottom: 8px;"></i>
                            No active parking bookings right now. Use the form above to reserve a slot.
                        </td>
                    </tr>
                <% } else {
                    for (Map<String, Object> a : allocations) {
                        String payStatus = String.valueOf(a.get("paymentStatus"));
                        boolean isPending = payStatus.toUpperCase().contains("PENDING");
                %>
                    <tr>
                        <td><strong><%= StringEscapeUtils.escapeHtml4(String.valueOf(a.get("vehicle"))) %></strong></td>
                        <td><%= StringEscapeUtils.escapeHtml4(String.valueOf(a.get("type"))) %></td>
                        <td><strong style="color: var(--primary); font-size: 1.05rem;"><%= StringEscapeUtils.escapeHtml4(String.valueOf(a.get("slot"))) %></strong></td>
                        <td><%= StringEscapeUtils.escapeHtml4(String.valueOf(a.get("floor"))) %></td>
                        <td><%= a.get("allocatedAt") == null ? "-" : dateFormat.format(a.get("allocatedAt")) %></td>
                        <td>
                            <span class="badge-cod">
                                <i class="fa-solid fa-money-bill-wave"></i> <%= a.get("paymentMethod") %>
                            </span>
                        </td>
                        <td><strong>₹<%= String.format("%.2f", (Double) a.get("amount")) %></strong></td>
                        <td>
                            <% if (isPending) { %>
                                <span class="badge-pending"><i class="fa-solid fa-clock"></i> <%= payStatus %></span>
                            <% } else { %>
                                <span class="badge-paid"><i class="fa-solid fa-circle-check"></i> <%= payStatus %></span>
                            <% } %>
                        </td>
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

<script>
    document.querySelectorAll('.payment-card input[type="radio"]').forEach(function(radio) {
        radio.addEventListener('change', function() {
            document.querySelectorAll('.payment-card').forEach(function(c) { c.classList.remove('selected'); });
            this.closest('.payment-card').classList.add('selected');
        });
    });
</script>

</body>
</html>
