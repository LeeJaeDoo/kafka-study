package com.jd.domain.entity;

import javax.persistence.Embeddable;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * @author Jaedoo Lee
 */
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Embeddable
@Builder
public class ConsumerIds {

    private String eventId;
    private String groupId;

    public static ConsumerIds of(String eventId, String groupId) {
        return ConsumerIds.builder().eventId(eventId).groupId(groupId).build();
    }

}
