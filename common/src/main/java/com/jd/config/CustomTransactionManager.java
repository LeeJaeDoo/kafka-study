package com.jd.config;

import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.TransactionStatus;
import org.springframework.transaction.support.DefaultTransactionDefinition;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.List;
import java.util.Stack;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * @author Jaedoo Lee
 */
@Component
@Scope("prototype")
@Slf4j
@RequiredArgsConstructor
public class CustomTransactionManager {

    private final PlatformTransactionManager transactionManager;

    private final ThreadLocal<Stack<TransactionStatus>> status = new ThreadLocal<>();

    public void start() {
        DefaultTransactionDefinition definition = new DefaultTransactionDefinition();
        definition.setName("customTransaction");
        definition.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        definition.setIsolationLevel(TransactionDefinition.ISOLATION_DEFAULT);
        definition.setTimeout(TransactionDefinition.TIMEOUT_DEFAULT);

        Stack<TransactionStatus> statuses = status.get();
        if (statuses == null) {
            statuses = new Stack<>();
            status.set(statuses);
        }

        statuses.push(transactionManager.getTransaction(definition));
        TransactionSynchronizationManager.setCurrentTransactionReadOnly(false);
    }

    public void rollback() {
        Stack<TransactionStatus> statuses = status.get();
        TransactionStatus currentStatus = statuses.pop();

        try {
            transactionManager.rollback(currentStatus);
        } catch (Exception e) {
            log.error("Transaction rollback error!");
        } finally {
            if (statuses.empty()) status.remove();
        }
    }

    public void commit() {
        List<TransactionStatus> statuses = status.get();
        TransactionStatus currentStatus = statuses.get(statuses.size() - 1);

        try {
            transactionManager.commit(currentStatus);
        } catch (Exception e) {
            log.error("Transaction commit error!");
        } finally {
            statuses.remove(currentStatus);
            if (statuses.size() == 0) status.remove();
        }
    }

}
