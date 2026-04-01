package com.example.ordersapi.model;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public class CreateOrderRequest {

        @NotBlank(message = "customerId is required")
        private String customerId;

        @NotBlank(message = "productId is required")
        private String productId;

        @NotNull(message = "totalAmount is required")
        @DecimalMin(value = "0.01", message = "totalAmount must be greater than zero")
        private BigDecimal totalAmount;

        private String couponCode;

        public String getCustomerId() {
                return customerId;
        }

        public void setCustomerId(String customerId) {
                this.customerId = customerId;
        }

        public String getProductId() {
                return productId;
        }

        public void setProductId(String productId) {
                this.productId = productId;
        }

        public BigDecimal getTotalAmount() {
                return totalAmount;
        }

        public void setTotalAmount(BigDecimal totalAmount) {
                this.totalAmount = totalAmount;
        }

        public String getCouponCode() {
                return couponCode;
        }

        public void setCouponCode(String couponCode) {
                this.couponCode = couponCode;
        }
}
