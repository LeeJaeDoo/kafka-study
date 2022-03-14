package com.jd.application;

import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.util.concurrent.ListenableFuture;
import org.springframework.util.concurrent.ListenableFutureCallback;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * @author Jaedoo Lee
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class KafkaService {

    private final KafkaTemplate<String, String> kafkaTemplate;

    @Async
    public void send(String topicName, String message) {

        ListenableFuture<SendResult<String, String>> future = kafkaTemplate.send(topicName, message);

        future.addCallback(new ListenableFutureCallback<SendResult<String, String>>() {

            @Override
            public void onSuccess(SendResult<String, String> result) {}

            public void onFailure(Throwable ex) {
                log.error("Unable to topic= {}, send message={} due to : {}", topicName, message, ex.getMessage());
            }
        });

    }

}
