package com.jd.domain.entity;

import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

import javax.persistence.Column;
import javax.persistence.EmbeddedId;
import javax.persistence.Entity;
import javax.persistence.EntityListeners;
import javax.persistence.Table;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * @author Jaedoo Lee
 */
@Getter
@Entity
@Table
@NoArgsConstructor
@AllArgsConstructor
@EntityListeners(AuditingEntityListener.class)
@Builder
public class IdempotenceConsumeLog {

    @EmbeddedId
    private ConsumerIds ids;

    private LocalDateTime publishedAt;

    @Column(updatable = false)
    private LocalDateTime createdAt;

    @Column(updatable = false)
    @LastModifiedDate
    private LocalDateTime updatedAt;

    public static IdempotenceConsumeLog of(ConsumerIds ids, LocalDateTime publishedAt) {
        return IdempotenceConsumeLog.builder().ids(ids).publishedAt(publishedAt).build();
    }
}
