package com.jd.config;

import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.jd.EventMessage;
import com.jd.domain.entity.ConsumerFailLog;
import com.jd.domain.repository.ConsumerFailLogRepository;

import org.apache.commons.lang3.ObjectUtils;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRebalanceListener;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.config.KafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.listener.CommonErrorHandler;
import org.springframework.kafka.listener.ContainerProperties;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.FixedBackOff;

import java.sql.SQLException;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import lombok.RequiredArgsConstructor;
import lombok.experimental.ExtensionMethod;
import lombok.extern.slf4j.Slf4j;

/**
 * @author Jaedoo Lee
 */
@Configuration
@RequiredArgsConstructor
@Slf4j
@ExtensionMethod({JacksonUtils.class, ObjectUtils.class})
public class KafkaConsumeConfig {

    private final ConsumerGroupProperties groupIds;
    private final ConsumerFactory<Object, Object> consumerFactory;
    private final ConsumerFailLogRepository failLogRepository;

    @Bean
    public ConcurrentKafkaListenerContainerFactory<Object, Object>
    kafkaListenerContainerFactory() {

        ConcurrentKafkaListenerContainerFactory<Object, Object> factory =
            new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory);
        return factory;
    }

    private KafkaListenerContainerFactory containerFactory(String groupId) {
        ConcurrentKafkaListenerContainerFactory<Object, Object> factory = kafkaListenerContainerFactory();
        factory.getContainerProperties().setAckMode(ContainerProperties.AckMode.MANUAL);
        factory.getContainerProperties().setGroupId(groupId);
        factory.getContainerProperties().setConsumerRebalanceListener(commonRebalanceListener());
        factory.setCommonErrorHandler(defaultErrorHandler(groupId));

        return factory;
    }

    @Bean
    public KafkaListenerContainerFactory test1ContainerFactory() {
        return containerFactory(groupIds.getTest1());
    }

    @Bean
    public KafkaListenerContainerFactory test2ContainerFactory() {
        return containerFactory(groupIds.getTest2());
    }

    private ConsumerRebalanceListener commonRebalanceListener() {
        return new ConsumerRebalanceListener() {

            @Override
            public void onPartitionsRevoked(Collection<TopicPartition> partitions) {
                log.info("consumer rebalacing start! {}", partitions.toString());
            }

            @Override
            public void onPartitionsAssigned(Collection<TopicPartition> partitions) {
                log.info("consumer rebalacing end! {}", partitions.toString());
            }
        };
    }

    private DefaultErrorHandler defaultErrorHandler(String groupId) {
        DefaultErrorHandler defaultErrorHandler =  new DefaultErrorHandler((consumerRecord, exception) -> {
            log.error("consumer error! groupId: {}, {}", groupId, consumerRecord.value(), exception);
            final String recordMessage =
                String.format(
                    "Consuming message error!!\nTopic : %s\nGroupId: %s\nPartitionNo : %s\nmessage : %s",
                    consumerRecord.topic(),
                    groupId,
                    consumerRecord.partition(),
                    consumerRecord.value());
            log.error("Retry {}, {}", recordMessage, consumerRecord, exception);

//            slackNotificationService.externalExceptionNotify(
//                properties.getHookUrl(), properties.getChannel(), recordMessage, exception);
            EventMessage message = null;
            try {
                message = extractMessage((ConsumerRecord<String, String>) consumerRecord);
                if (!failLogRepository.existsByEventIdAndGroupId(message.getEventId(), groupId)) {
                    failLogRepository.save(
                        ConsumerFailLog.of(
                            consumerRecord.topic(),
                            consumerRecord.partition(),
                            message,
                            groupId,
                            exception));
                }
            } catch (final Exception e) {
                String eventId = message == null ? null : message.getEventId();
                log.error("fail log save error! {}", eventId, e);
//                slackNotificationService.externalExceptionNotify(
//                    properties.getHookUrl(),
//                    properties.getChannel(),
//                    "fail log save error! eventId: " + eventId,
//                    e);
            }

        }, new FixedBackOff(1000L, 3L));

        defaultErrorHandler.addNotRetryableExceptions(RuntimeException.class, SQLException.class, JsonProcessingException.class);

        return defaultErrorHandler;
    }

    private EventMessage extractMessage(ConsumerRecord<String, String> consumerRecord) {
        return consumerRecord.value().toModelOrNull(EventMessage.class).defaultIfNull(new EventMessage());
    }

}
