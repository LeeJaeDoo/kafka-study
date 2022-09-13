package com.jd.infrastructure;

import com.zaxxer.hikari.HikariDataSource;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.LazyConnectionDataSourceProxy;

import java.util.HashMap;
import java.util.Map;

import javax.sql.DataSource;

/**
 * @author Jaedoo Lee
 */
@Configuration
public class DataSourceConfig {

    @Bean
    @ConfigurationProperties(prefix = "spring.datasource.consume-domain.read")
    public DataSource consumerReadDataSource() {
        return DataSourceBuilder.create().type(HikariDataSource.class).build();
    }

    @Bean
    @ConfigurationProperties(prefix = "spring.datasource.consume-domain.write")
    public DataSource consumerWriteDataSource() {
        return DataSourceBuilder.create().type(HikariDataSource.class).build();
    }

    private Map<Object, Object> targetDataSources() {
        Map<Object, Object> targetDataSourceMap = new HashMap<>();
        targetDataSourceMap.put("read", consumerReadDataSource());
        targetDataSourceMap.put("write", consumerWriteDataSource());

        return targetDataSourceMap;
    }

    @Bean
    public DataSource consumerRoutingSource() {
        ConsumerReplicationRoutingDataSource routingDataSource = new ConsumerReplicationRoutingDataSource();
        routingDataSource.setTargetDataSources(targetDataSources());
        routingDataSource.setDefaultTargetDataSource(consumerReadDataSource());

        return routingDataSource;
    }

    @Bean
    public DataSource consumerDataSource() {
        return new LazyConnectionDataSourceProxy(consumerRoutingSource());
    }
}
