package com.jd.domain.entity;

import com.jd.BaseEntity;
import com.jd.EventMessage;
import com.jd.config.JacksonUtils;

import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.ExtensionMethod;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import javax.persistence.*;
import javax.validation.constraints.NotNull;
import java.time.LocalDateTime;

@Getter
@Entity
@NoArgsConstructor
@EntityListeners(AuditingEntityListener.class)
@ExtensionMethod(JacksonUtils.class)
@Table
public class ConsumerFailLog extends BaseEntity {

    @Column(updatable = false)
    @CreatedDate
    protected LocalDateTime createdAt;

    @Column(updatable = false)
    @LastModifiedDate
    protected LocalDateTime updatedAt;

    private String eventId;
    private String topic;

//    @Enumerated(EnumType.STRING)
//    private EventType eventType;

    private String groupId;
    private Integer partitionNo;
    private String payload;
    private String failMessage;
    private LocalDateTime retriedAt;
    private LocalDateTime publishedAt;

    public void messageRetry() {
        this.retriedAt = LocalDateTime.now();
    }

    @Builder
    public ConsumerFailLog(
        @NotNull final String topic,
        final Integer partitionNo,
        @NotNull final String eventId,
//        @NotNull final EventType eventType,
        final String groupId,
        @NotNull final String payload,
        final String failMessage,
        final LocalDateTime publishedAt) {
        this.topic = topic;
        this.partitionNo = partitionNo;
        this.eventId = eventId;
//        this.eventType = eventType;
        this.groupId = groupId;
        this.payload = payload;
        this.failMessage = failMessage;
        this.publishedAt = publishedAt;
    }

    public static ConsumerFailLog of(
        final String topic,
        final int partitionNo,
        final EventMessage message,
        final String consumerGroupId,
        final Exception ex) {
        return ConsumerFailLog.builder()
                              .topic(topic)
                              .partitionNo(partitionNo)
                              .eventId(message.getEventId())
//                              .eventType(message.getEventType())
                              .groupId(consumerGroupId)
                              .payload(message.getPayload().toJson())
                              .failMessage(ex.getMessage())
                              .publishedAt(message.getPublishedAt())
                              .build();
    }
}

