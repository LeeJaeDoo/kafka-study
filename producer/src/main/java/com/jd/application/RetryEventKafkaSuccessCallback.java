package com.jd.application;

import com.jd.DomainEvent;
import com.jd.EventMessage;
import com.jd.config.JacksonUtils;
import com.jd.domain.entity.ConsumerFailLog;
import com.jd.domain.repository.ConsumerFailLogRepository;
//import com.withinapi.quickdiscount.common.errors.SlackNotiProperties;
//import com.withinapi.quickdiscount.common.slack.SlackNotificationService;
import lombok.RequiredArgsConstructor;
import lombok.experimental.ExtensionMethod;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.concurrent.SuccessCallback;

import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
@ExtensionMethod({JacksonUtils.class})
public class RetryEventKafkaSuccessCallback implements SuccessCallback<SendResult<String, Object>> {

    private final ConsumerFailLogRepository failLogRepository;
//    private final SlackNotiProperties notiProperties;
//    private final SlackNotificationService slackNotificationService;

    @Override
    @Transactional(transactionManager = "quickDiscountLogTransactionManager")
    public void onSuccess(SendResult<String, Object> result) {
        String eventId = null;
        try {
            final DomainEvent<?> domainEvent =
                result.getProducerRecord().value().toString().toModel(EventMessage.class);
            eventId = domainEvent.getEventId();
            final List<ConsumerFailLog> failLogs = failLogRepository.findByEventId(eventId);

            if (failLogs.isEmpty()) {
                throw new Exception(
                    "eventId : " + domainEvent.getEventId() + "를 찾을 수 없습니다.");
            }

            for (ConsumerFailLog failLog : failLogs) {
                failLog.messageRetry();
            }
        } catch (Exception e) {
            log.error("[Kafka fail message retry logging fail]", e);
//            slackNotificationService.externalExceptionNotify(
//                notiProperties.getHookUrl(),
//                notiProperties.getChannel(),
//                "카프카 실패 메세지 재시도 처리는 성공했으나 retriedAt 여부 저장에 실패했습니다. 조치가 필요합니다. evnetId: " + eventId,
//                e);
        }

        log.info("[Kafka fail message retry send success] " + result.getRecordMetadata());
    }
}
