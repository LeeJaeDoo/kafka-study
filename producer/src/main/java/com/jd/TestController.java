package com.jd;

import com.jd.application.KafkaService;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

/**
 * @author Jaedoo Lee
 */
@RestController
@RequiredArgsConstructor
@RequestMapping("/kafka/test")
public class TestController {

    private final KafkaService kafkaService;

    @PostMapping
    public ResponseEntity<?> sendKafka() {

        kafkaService.send("test", "first jump!");

        return ResponseEntity.noContent().build();
    }

}
