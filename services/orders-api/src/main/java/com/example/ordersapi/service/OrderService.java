package com.example.ordersapi.service;

import com.example.ordersapi.model.CreateOrderRequest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
public class OrderService {

    private final JdbcTemplate jdbcTemplate;

    public OrderService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
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

        String payload = "{" +
            "\"order_id\":\"%s\"," +
            "\"customer_id\":\"%s\"," +
            "\"product_id\":\"%s\"," +
            "\"total_amount\":%s," +
            "\"created_at\":\"%s\"," +
            "\"coupon_code\":%s" +
            "}";

        payload = payload.formatted(
                orderId,
            request.getCustomerId(),
            request.getProductId(),
            request.getTotalAmount(),
                now,
            request.getCouponCode() == null ? "null" : "\"" + request.getCouponCode() + "\""
        );

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
