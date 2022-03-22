package com.jd.listener;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.hibernate5.Hibernate5Module;
import com.fasterxml.jackson.datatype.jdk8.Jdk8Module;
import com.jd.TestRequest;

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
        ObjectMapper mapper = getObjectMapper();
        mapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
        TestRequest request = mapper.readValue(message, TestRequest.class);
        System.out.printf("Consumed message, id : %s, name : %s%n", request.getId(), request.getName());
    }

    public static ObjectMapper getObjectMapper() {
        ObjectMapper objectMapper = new ObjectMapper();

        objectMapper.registerModule(new Hibernate5Module());
        objectMapper.registerModule(new Jdk8Module()); // Optional 처리

        return objectMapper;
    }

}
