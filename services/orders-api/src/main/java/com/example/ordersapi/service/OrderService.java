package com.example.ordersapi.service;

import com.example.ordersapi.model.CreateOrderRequest;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class OrderService {

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;

    public OrderService(JdbcTemplate jdbcTemplate, ObjectMapper objectMapper) {
        this.jdbcTemplate = jdbcTemplate;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public UUID createOrder(CreateOrderRequest request) {
        UUID orderId = UUID.randomUUID();
        Instant now = Instant.now();

        jdbcTemplate.update(
            "INSERT INTO orders (order_id, customer_id, product_id, total_amount, coupon_code, created_at) " +
                "VALUES (?, ?, ?, ?, ?, ?)",
                orderId,
            request.getCustomerId(),
            request.getProductId(),
            request.getTotalAmount(),
            request.getCouponCode(),
                now
        );

        Map<String, Object> payloadMap = new LinkedHashMap<>();
        payloadMap.put("order_id", orderId.toString());
        payloadMap.put("customer_id", request.getCustomerId());
        payloadMap.put("product_id", request.getProductId());
        payloadMap.put("total_amount", request.getTotalAmount());
        payloadMap.put("created_at", now.toString());
        payloadMap.put("coupon_code", request.getCouponCode());

        String payload;
        try {
            payload = objectMapper.writeValueAsString(payloadMap);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Failed to serialize outbox payload", e);
        }

        jdbcTemplate.update(
            "INSERT INTO outbox_events (aggregate_type, aggregate_id, event_type, payload, created_at) " +
                "VALUES (?, ?, ?, cast(? as jsonb), ?)",
                "ORDER",
                orderId.toString(),
                "OrderCreated",
                payload,
                now
        );

        return orderId;
    }
}
