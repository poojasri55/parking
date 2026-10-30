package com.parkwise.servlet;

import com.parkwise.config.DBConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/parking-slots")
public class ParkingSlotServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request,
                         HttpServletResponse response)
            throws ServletException, IOException {

        List<Map<String, Object>> slots = new ArrayList<>();

        try (Connection con = DBConnection.getConnection()) {

            String sql = "SELECT id, slot_number, floor_name, "
                       + "vehicle_type, status "
                       + "FROM parking_slots ORDER BY slot_number";

            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> slot = new HashMap<>();

                    slot.put("id", rs.getLong("id"));
                    slot.put("slotNumber", rs.getString("slot_number"));
                    slot.put("floorName", rs.getString("floor_name"));
                    slot.put("vehicleType", rs.getString("vehicle_type"));
                    slot.put("status", rs.getString("status"));

                    slots.add(slot);
                }
            }

            request.setAttribute("slots", slots);
            request.getRequestDispatcher("/parking-slots.jsp")
                   .forward(request, response);

        } catch (SQLException e) {
            log("Error loading parking slots", e);
            response.sendError(
                HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                "Unable to load parking slots. Check the database configuration."
            );
        }
    }
}