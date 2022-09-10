package com.jd.listener;

import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;

/**
 * @author Jaedoo Lee
 */
public interface IdempotenceMessageListener {

    void idempotenceOnMessage(@Header(value = KafkaHeaders.GROUP_ID) String groupId, String message, Acknowledgment acknowledgment);

}
