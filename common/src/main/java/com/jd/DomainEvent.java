package com.jd;

import java.time.LocalDateTime;

/**
 * @author Jaedoo Lee
 */
public interface DomainEvent<T> {

    String getEventId();
//    EventType getEventType();
    T getPayload();
    LocalDateTime getPublishedAt();
}
