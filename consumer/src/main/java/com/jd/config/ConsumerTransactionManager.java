package com.jd.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * @author Jaedoo Lee
 */
@Component
@Scope("prototype")
@Slf4j
public class ConsumerTransactionManager extends CustomTransactionManager {

    public ConsumerTransactionManager(@Qualifier("consumeTransactionManager") PlatformTransactionManager transactionManager) {

        super(transactionManager);
    }
}
