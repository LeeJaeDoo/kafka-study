package com.jd.domain.repository;

import com.jd.domain.entity.ConsumerIds;
import com.jd.domain.entity.IdempotenceConsumeLog;

import org.springframework.data.jpa.repository.JpaRepository;

/**
 * @author Jaedoo Lee
 */
public interface IdempotenceConsumeLogRepository extends JpaRepository<IdempotenceConsumeLog, ConsumerIds> {}
