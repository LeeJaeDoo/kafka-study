package com.jd.config;

import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.core.JsonProcessingException;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRebalanceListener;
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
import lombok.extern.slf4j.Slf4j;

/**
 * @author Jaedoo Lee
 */
@Configuration
@RequiredArgsConstructor
@Slf4j
public class KafkaConsumeConfig {

    private final ConsumerGroupProperties groupIds;
    private final ConsumerFactory<Object, Object> consumerFactory;

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
        }, new FixedBackOff(1000L, 3L));

        defaultErrorHandler.addNotRetryableExceptions(RuntimeException.class, SQLException.class, JsonProcessingException.class);

        return defaultErrorHandler;
    }

}
