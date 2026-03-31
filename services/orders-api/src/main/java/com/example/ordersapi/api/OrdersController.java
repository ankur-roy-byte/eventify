package com.example.ordersapi.api;

import com.example.ordersapi.model.CreateOrderRequest;
import com.example.ordersapi.service.OrderService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/orders")
public class OrdersController {

    private final OrderService orderService;

    public OrdersController(OrderService orderService) {
        this.orderService = orderService;
    }

    @PostMapping
    public ResponseEntity<Map<String, String>> create(@RequestBody CreateOrderRequest request) {
        UUID orderId = orderService.createOrder(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("orderId", orderId.toString()));
    }
}
