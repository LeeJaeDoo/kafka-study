package com.jd.domain.repository;

import com.jd.domain.entity.ConsumerFailLog;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * @author Jaedoo Lee
 */
public interface ConsumerFailLogRepository extends JpaRepository<ConsumerFailLog, Long> {

    List<ConsumerFailLog> findByRetriedAtIsNull();
    List<ConsumerFailLog> findByEventId(String eventId);
    boolean existsByEventIdAndGroupId(String eventId, String groupId);

}
