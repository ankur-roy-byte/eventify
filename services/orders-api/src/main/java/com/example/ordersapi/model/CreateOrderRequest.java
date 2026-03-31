package com.example.ordersapi.model;

import java.math.BigDecimal;

public class CreateOrderRequest {

        private String customerId;
        private String productId;
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
