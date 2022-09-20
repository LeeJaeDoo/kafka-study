package com.jd.config;

import com.jd.EventMessage;
import com.jd.domain.entity.ConsumerIds;
import com.jd.domain.entity.IdempotenceConsumeLog;
import com.jd.domain.repository.IdempotenceConsumeLogRepository;

import org.apache.commons.lang3.StringUtils;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.converter.KafkaMessageHeaders;
import org.springframework.stereotype.Component;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

import lombok.RequiredArgsConstructor;

/**
 * @author Jaedoo Lee
 */
@Aspect
@Component
@RequiredArgsConstructor
public class IdempotenceConsumeHandler {

    private final IdempotenceConsumeLogRepository consumeLogRepository;
    private final ConsumerTransactionManager transactionManager;

    @Around("execution(* com.jd.listener.*.idempotenceOnMessage(..))")
    public void idempotenceConsumeHandler(ProceedingJoinPoint joinPoint) throws Throwable {
        Object[] args = joinPoint.getArgs();
        String groupId = (String) args[0];
        EventMessage messsage = JacksonUtils.toModel((String) args[1], EventMessage.class);
        Acknowledgment acknowledgment = (Acknowledgment) args[2];


        transactionManager.start();
        try {
            if (!requiredIdempotenceConsume(messsage.getEventId(), groupId)) {
                return;
            }

            ConsumerIds consumerIds = ConsumerIds.of(messsage.getEventId(), groupId);
            if (consumeLogRepository.existsById(consumerIds)) {
                return;
            }

            consumeLogRepository.save(IdempotenceConsumeLog.of(consumerIds, messsage.getPublishedAt()));
            joinPoint.proceed();
            transactionManager.commit();
        } catch (Exception e) {
            transactionManager.rollback();
        } finally {
            acknowledgment.acknowledge();
        }
    }

    private boolean requiredIdempotenceConsume(String eventId, String groupId) {
        return StringUtils.isNoneBlank(eventId, groupId);
    }

    private String extractStringHeader(String headerKey, KafkaMessageHeaders headers) {
        return headers.get(headerKey) == null ? null : new String((byte[]) headers.get(headerKey), StandardCharsets.UTF_8);
    }

    private String extractStringHeader(String headerKey, ConsumerRecord consumerRecord) {
        return Arrays.stream(consumerRecord.headers().toArray())
            .filter(header -> headerKey.equals(header.key()))
            .map(header -> new String(ByteBuffer.wrap(header.value()).array(), StandardCharsets.UTF_8))
            .findFirst()
            .orElse(null);
    }

}
