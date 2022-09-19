package com.jd.infrastructure;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.NestedConfigurationProperty;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;

/**
 * @author Jaedoo Lee
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "spring.jpa.properties.hibernate")
@Component
public class HibernateProperties {

    private String defaultBatchFetchSize;
    @NestedConfigurationProperty
    private Hbm2ddl Hbm2ddl;
    @NestedConfigurationProperty
    private Query query;
    private String showSql;
    private String formatSql;
    private String useSqlComments;
    private String dialect;
    private String physicalNamingStrategy;

    @Getter
    @Setter
    public static class Hbm2ddl {
        private String auto;
    }

    @Getter
    @Setter
    public static class Query {
        private String failOnPaginationOverCollectionFetch;
    }

}
