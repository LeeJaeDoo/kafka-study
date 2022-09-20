package com.jd;

import java.time.LocalDateTime;
import java.util.UUID;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * @author Jaedoo Lee
 */
@Getter
@NoArgsConstructor
@Builder
public class EventMessage implements DomainEvent<Object> {

    protected String eventId;
//    protected EventType eventType;
    protected Object payload;
    protected LocalDateTime publishedAt;

    public EventMessage(String eventId,
//                        EventType eventType,
                        Object payload, LocalDateTime publishedAt) {
        this.eventId = UUID.randomUUID().toString();
//        this.eventType = eventType;
        this.payload = payload;
        this.publishedAt = LocalDateTime.now();
    }
}
