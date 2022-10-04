package com.jd.listener;

import com.jd.EventMessage;
import com.jd.domain.entity.EventPublishedLog;
import com.jd.domain.repository.EventPublishedLogRepository;

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
public class TestApplicationEventListener {

    private final EventPublishedLogRepository logRepository;

    @Async
    @TransactionalEventListener(phase = TransactionPhase.BEFORE_COMMIT)
    public void onApplicationEvent(EventMessage event) {
        logRepository.save(EventPublishedLog.of(event));
    }

}
