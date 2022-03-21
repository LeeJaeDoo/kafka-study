package com.jd.listener;

import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * @author Jaedoo Lee
 */
@Component
public class TestListener {

    @KafkaListener(topics = "test", groupId = "foo")
    public void consume(String message) throws IOException {
        System.out.printf("Consumed message : %s%n", message);
    }

}
