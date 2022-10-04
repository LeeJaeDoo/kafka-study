package com.jd.application;

import com.jd.DomainEvent;
import com.jd.config.JacksonUtils;

import org.apache.kafka.clients.producer.ProducerRecord;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * @author Jaedoo Lee
 */
@Slf4j
@RequiredArgsConstructor
@Service
public class DomainEventKafkaService {

    private final KafkaTemplate<String, Object> kafkaTemplate;
    private final DomainEventKafkaSuccessCallback domainEventKafkaSuccessCallback;
    private final RetryEventKafkaSuccessCallback retryEventKafkaSuccessCallback;
    private final EventKafkaFailureCallback eventKafkaFailureCallback;

    public void sendKafkaProducer(String topic, DomainEvent<?> value) {
        kafkaTemplate.send(new ProducerRecord<>(topic, JacksonUtils.toJson(value)))
                     .addCallback(domainEventKafkaSuccessCallback, eventKafkaFailureCallback);
    }

    public void sendKafkaProducerForRetry(String topic, DomainEvent<?> value) {
        kafkaTemplate.send(new ProducerRecord<>(topic, JacksonUtils.toJson(value)))
                     .addCallback(retryEventKafkaSuccessCallback, eventKafkaFailureCallback);
    }

}
