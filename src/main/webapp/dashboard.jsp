<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="com.parkwise.model.User" %>
<%
    User currentUser = (User) session.getAttribute("user");

    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Dashboard | PARKWISE</title>
    <link rel="stylesheet" href="app-header.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        .welcome-hero {
            background: linear-gradient(135deg, #087f8c, #055f69);
            border-radius: 16px;
            padding: 2.25rem;
            color: #ffffff;
            margin-bottom: 2rem;
            box-shadow: 0 10px 25px -5px rgba(8, 127, 140, 0.25);
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 1.5rem;
        }

        .welcome-hero h1 {
            font-size: 1.85rem;
            font-weight: 800;
            margin-bottom: 6px;
        }

        .welcome-hero p {
            color: rgba(255, 255, 255, 0.85);
            font-size: 1rem;
        }

        .user-tag {
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(8px);
            padding: 8px 16px;
            border-radius: 30px;
            font-size: 0.88rem;
            font-weight: 600;
        }

        .modules-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 1.5rem;
        }

        .module-card {
            background: #ffffff;
            border-radius: 14px;
            border: 1px solid var(--border-color);
            padding: 1.75rem;
            text-decoration: none;
            color: inherit;
            display: flex;
            flex-direction: column;
            gap: 12px;
            box-shadow: var(--shadow-sm);
            transition: all 0.25s ease;
            position: relative;
            overflow: hidden;
        }

        .module-card:hover {
            transform: translateY(-4px);
            box-shadow: var(--shadow-lg);
            border-color: var(--primary);
        }

        .module-icon {
            width: 52px;
            height: 52px;
            border-radius: 12px;
            background: var(--primary-light);
            color: var(--primary);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
        }

        .module-card h3 {
            font-size: 1.2rem;
            font-weight: 700;
            color: var(--text-main);
            margin: 0;
        }

        .module-card p {
            font-size: 0.92rem;
            color: var(--text-muted);
            line-height: 1.5;
            margin: 0;
        }

        .module-card .action-link {
            font-size: 0.88rem;
            font-weight: 700;
            color: var(--primary);
            display: flex;
            align-items: center;
            gap: 6px;
            margin-top: auto;
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
            <li><a href="dashboard.jsp" class="active"><i class="fa-solid fa-gauge"></i> <span>Dashboard</span></a></li>
            <li><a href="vehicles"><i class="fa-solid fa-car"></i> <span>Vehicles</span></a></li>
            <li><a href="parking-slots"><i class="fa-solid fa-square-parking"></i> <span>Slots</span></a></li>
            <li><a href="allocations"><i class="fa-solid fa-clipboard-check"></i> <span>Bookings</span></a></li>
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

    <!-- Welcome Hero Banner -->
    <div class="welcome-hero">
        <div>
            <h1>Welcome back, <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(currentUser.getFullName()) %>!</h1>
            <p>Access your vehicles, reserve parking spots, and monitor allocation status.</p>
        </div>
        <div class="user-tag">
            <i class="fa-solid fa-shield-halved"></i> Role: <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(currentUser.getRole()) %>
        </div>
    </div>

    <!-- Modules Navigation Grid -->
    <div class="modules-grid">

        <a class="module-card" href="vehicles">
            <div class="module-icon">
                <i class="fa-solid fa-car"></i>
            </div>
            <h3>Vehicle Module</h3>
            <p>Register and manage your cars, bikes, scooters, or commercial vehicles.</p>
            <span class="action-link">Manage Vehicles <i class="fa-solid fa-arrow-right"></i></span>
        </a>

        <a class="module-card" href="parking-slots">
            <div class="module-icon">
                <i class="fa-solid fa-square-parking"></i>
            </div>
            <h3>Parking Slots</h3>
            <p>Check real-time slot vacancy and capacity across all floors and vehicle types.</p>
            <span class="action-link">View Directory <i class="fa-solid fa-arrow-right"></i></span>
        </a>

        <a class="module-card" href="allocations">
            <div class="module-icon">
                <i class="fa-solid fa-clipboard-check"></i>
            </div>
            <h3>Slot Allocation</h3>
            <p>Reserve available parking slots for your registered vehicles or release bays.</p>
            <span class="action-link">Book or Release <i class="fa-solid fa-arrow-right"></i></span>
        </a>

        <a class="module-card" href="monitoring">
            <div class="module-icon">
                <i class="fa-solid fa-video"></i>
            </div>
            <h3>Vehicle Monitoring</h3>
            <p>Track real-time gate entry and exit timestamp records for your parking sessions.</p>
            <span class="action-link">View Activity <i class="fa-solid fa-arrow-right"></i></span>
        </a>

        <% if ("ADMIN".equalsIgnoreCase(currentUser.getRole())) { %>
        <a class="module-card" href="admin" style="border-color: #86efac; background: #f0fdf4;">
            <div class="module-icon" style="background: #dcfce7; color: #166534;">
                <i class="fa-solid fa-shield-halved"></i>
            </div>
            <h3>Admin Portal</h3>
            <p>Administrative system overview, registered accounts audit, and access management.</p>
            <span class="action-link" style="color: #166534;">Open Admin Console <i class="fa-solid fa-arrow-right"></i></span>
        </a>
        <% } %>

    </div>

</main>

<!-- Unified Footer -->
<footer class="app-footer">
    <p>&copy; 2026 <span>PARKWISE</span> — Smart Vehicle Parking Allocation & Monitoring System. All rights reserved.</p>
</footer>

</body>
</html>