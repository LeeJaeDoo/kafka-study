package com.jd.application;

import com.jd.EventMessage;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * @author Jaedoo Lee
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class TestEventKafkaListener {

    private final DomainEventKafkaService domainEventKafkaService;

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onEventListener(EventMessage event) {
        domainEventKafkaService.sendKafkaProducer("test", event);
    }

}
