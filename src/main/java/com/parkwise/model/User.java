package com.parkwise.model;

public class User {
    private final long id;
    private final String fullName;
    private final String email;
    private final String phone;
    private final String role;

    public User(long id, String fullName, String email, String phone, String role) {
        this.id = id; this.fullName = fullName; this.email = email; this.phone = phone; this.role = role;
    }
    public long getId() { return id; }
    public String getFullName() { return fullName; }
    public String getEmail() { return email; }
    public String getPhone() { return phone; }
    public String getRole() { return role; }
}
