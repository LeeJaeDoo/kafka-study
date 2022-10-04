package com.jd.application;

import org.springframework.kafka.core.KafkaFailureCallback;
import org.springframework.kafka.core.KafkaProducerException;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * @author Jaedoo Lee
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class EventKafkaFailureCallback implements KafkaFailureCallback {

    @Override
    public void onFailure(KafkaProducerException ex) {
        String topic = ex.getFailedProducerRecord().topic();
        Object value = ex.getFailedProducerRecord().value();
        log.error("kafka message publish fail!, topic : {}, value : {}, {}", topic, value, ex.getMessage(), ex);
    }
}
