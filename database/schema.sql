-- =======================================================
-- PARKWISE Complete Database Schema
-- Vehicle Parking Allocation and Monitoring System
-- =======================================================

CREATE DATABASE IF NOT EXISTS parkwise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE parkwise;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  phone VARCHAR(20) NOT NULL,
  password_hash VARCHAR(60) NOT NULL,
  role ENUM('USER','ADMIN') NOT NULL DEFAULT 'USER',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Vehicles Table
CREATE TABLE IF NOT EXISTS vehicles (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  registration_number VARCHAR(20) NOT NULL UNIQUE,
  vehicle_type VARCHAR(30) NOT NULL,
  vehicle_model VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_vehicles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. Parking Slots Table
CREATE TABLE IF NOT EXISTS parking_slots (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  slot_number VARCHAR(20) NOT NULL UNIQUE,
  floor_name VARCHAR(50) NOT NULL,
  vehicle_type VARCHAR(30) NOT NULL,
  status ENUM('AVAILABLE','OCCUPIED','MAINTENANCE') NOT NULL DEFAULT 'AVAILABLE',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. Allocations Table (Slot Bookings)
CREATE TABLE IF NOT EXISTS allocations (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  vehicle_id BIGINT NOT NULL,
  slot_id BIGINT NOT NULL,
  status ENUM('ACTIVE','RELEASED') NOT NULL DEFAULT 'ACTIVE',
  allocated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  released_at TIMESTAMP NULL DEFAULT NULL,
  CONSTRAINT fk_allocations_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_allocations_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
  CONSTRAINT fk_allocations_slot FOREIGN KEY (slot_id) REFERENCES parking_slots(id) ON DELETE CASCADE
);

-- 5. Monitoring Records Table
CREATE TABLE IF NOT EXISTS monitoring_records (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  allocation_id BIGINT NOT NULL,
  entry_time TIMESTAMP NULL DEFAULT NULL,
  exit_time TIMESTAMP NULL DEFAULT NULL,
  status ENUM('NOT_ENTERED','INSIDE','EXITED') NOT NULL DEFAULT 'NOT_ENTERED',
  CONSTRAINT fk_monitoring_allocation FOREIGN KEY (allocation_id) REFERENCES allocations(id) ON DELETE CASCADE
);

-- Seed Initial Parking Slots (if empty)
INSERT IGNORE INTO parking_slots (slot_number, floor_name, vehicle_type, status) VALUES
('A-101', 'Ground Floor (Level 0)', 'Car', 'AVAILABLE'),
('A-102', 'Ground Floor (Level 0)', 'Car', 'AVAILABLE'),
('A-103', 'Ground Floor (Level 0)', 'Car', 'AVAILABLE'),
('B-201', '1st Floor (Level 1)', 'Bike', 'AVAILABLE'),
('B-202', '1st Floor (Level 1)', 'Bike', 'AVAILABLE'),
('B-203', '1st Floor (Level 1)', 'Scooter', 'AVAILABLE'),
('C-301', 'Basement (Level -1)', 'Van', 'AVAILABLE'),
('EV-101', 'Ground Floor (Level 0)', 'Car', 'AVAILABLE');
