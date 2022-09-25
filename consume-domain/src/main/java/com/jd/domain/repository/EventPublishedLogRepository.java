package com.jd.domain.repository;

import com.jd.domain.entity.EventPublishedLog;

import org.springframework.data.jpa.repository.JpaRepository;

/**
 * @author Jaedoo Lee
 */
public interface EventPublishedLogRepository extends JpaRepository<EventPublishedLog, Long> {}
