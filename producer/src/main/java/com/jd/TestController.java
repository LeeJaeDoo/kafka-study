package com.jd;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.hibernate5.Hibernate5Module;
import com.fasterxml.jackson.datatype.jdk8.Jdk8Module;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fasterxml.jackson.datatype.jsr310.deser.LocalDateTimeDeserializer;
import com.fasterxml.jackson.datatype.jsr310.ser.LocalDateTimeSerializer;
import com.jd.application.KafkaService;
import com.jd.application.TestRequest;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

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
    public ResponseEntity<?> sendKafka(@RequestBody TestRequest request) throws JsonProcessingException {
        ObjectMapper mapper = getObjectMapper();

        kafkaService.send("test", mapper.writeValueAsString(request));

        return ResponseEntity.noContent().build();
    }

    public static ObjectMapper getObjectMapper() {
        ObjectMapper objectMapper = new ObjectMapper();

        objectMapper.registerModule(new Hibernate5Module());
        objectMapper.registerModule(new Jdk8Module()); // Optional 처리

        return objectMapper;
    }

}
