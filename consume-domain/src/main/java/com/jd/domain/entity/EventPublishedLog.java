package com.jd.domain.entity;

import com.jd.BaseEntity;
import com.jd.EventMessage;
import com.jd.config.JacksonUtils;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Enumerated;
import javax.persistence.Table;
import javax.validation.constraints.NotNull;

import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * @author Jaedoo Lee
 */
@Getter
@Entity
@Table(name = "tb_event_published_log")
@NoArgsConstructor
public class EventPublishedLog extends BaseEntity {

    @Column(name = "event_id")
    private String eventId;

//    @Column(name = "event_type")
//    @Enumerated(EnumType.STRING)
//    private EventType eventType;

    private String payload;

    @Builder
    public EventPublishedLog(
        @NotNull final String eventId,
//        @NotNull final EventType eventType,
        @NotNull final Object payload) {
        this.eventId = eventId;
//        this.eventType = eventType;
        this.payload = JacksonUtils.toJson(payload);
    }

    public static EventPublishedLog of(final EventMessage event) {
        return EventPublishedLog.builder()
                                .eventId(event.getEventId())
//                                .eventType(event.getEventType())
                                .payload(event.getPayload())
                                .build();
    }
}
