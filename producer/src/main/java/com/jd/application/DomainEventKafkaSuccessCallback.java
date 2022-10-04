package com.jd.application;

import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.concurrent.SuccessCallback;


import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;

/**
 * @author Jaedoo Lee
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class DomainEventKafkaSuccessCallback implements SuccessCallback<SendResult<String, Object>> {

    @SneakyThrows
    @Override
    @Transactional
    public void onSuccess(SendResult<String, Object> result) {
        log.info("[Kafka message send success] " + result.getRecordMetadata().toString());
    }
}
