package com.jd.listener;

import org.springframework.kafka.annotation.KafkaListener;

import java.io.IOException;

/**
 * @author Jaedoo Lee
 */

public class TestListener {

    @KafkaListener(topics = "test")
    public void consume(String message) throws IOException {
        System.out.printf("Consumed message : %s%n", message);
    }

}
