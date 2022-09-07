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
public class EventMesssage {

    protected final String eventId = UUID.randomUUID().toString();
    protected final LocalDateTime publishedAt = LocalDateTime.now();
}
