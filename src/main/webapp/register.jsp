<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Create PARKWISE account</title>
    <link rel="stylesheet" href="auth.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body class="auth-page">
<main class="auth-card">
    <a class="brand" href="index.html">
        <i class="fa-solid fa-square-parking"></i> PARKWISE
    </a>
    <h1>Create your account</h1>
    <p class="muted">Register to manage your parking bookings and vehicles.</p>

    <% if (request.getAttribute("error") != null) { %>
        <div class="alert error"><i class="fa-solid fa-triangle-exclamation"></i> <%= org.apache.commons.text.StringEscapeUtils.escapeHtml4(String.valueOf(request.getAttribute("error"))) %></div>
    <% } %>

    <form method="post" action="register" autocomplete="on">
        <label for="fullName">Full name</label>
        <input id="fullName" name="fullName" required minlength="2" maxlength="100" autocomplete="name" placeholder="John Doe">
        <label for="email">Email address</label>
        <input id="email" name="email" type="email" required maxlength="190" autocomplete="email" placeholder="john@example.com">
        <label for="phone">Phone number</label>
        <input id="phone" name="phone" type="tel" required minlength="7" maxlength="20" autocomplete="tel" placeholder="+1 555-0199">
        <label for="password">Password (8–72 characters)</label>
        <input id="password" name="password" type="password" required minlength="8" maxlength="72" autocomplete="new-password">
        <label for="confirmPassword">Confirm password</label>
        <input id="confirmPassword" name="confirmPassword" type="password" required minlength="8" maxlength="72" autocomplete="new-password">
        <button type="submit">Create account</button>
    </form>
    <p class="switch">Already registered? <a href="login.jsp">Sign in</a></p>
    <a class="home" href="index.html">&larr; Back to home</a>
</main>
</body>
</html>
