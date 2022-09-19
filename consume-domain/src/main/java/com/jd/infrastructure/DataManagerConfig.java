package com.jd.infrastructure;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.dao.annotation.PersistenceExceptionTranslationPostProcessor;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import java.util.Objects;
import java.util.Properties;

import javax.annotation.PostConstruct;
import javax.persistence.EntityManagerFactory;
import javax.sql.DataSource;

import lombok.RequiredArgsConstructor;
import lombok.experimental.ExtensionMethod;

/**
 * @author Jaedoo Lee
 */
@Configuration
@EnableTransactionManagement
@EnableJpaRepositories(
    basePackages = {"com.jd.domain"},
    entityManagerFactoryRef = "consumerEntityManagerFactory",
    transactionManagerRef = "consumeTransactionManager"
)
@RequiredArgsConstructor
@ExtensionMethod(Objects.class)
public class DataManagerConfig {

    private static HibernateProperties hibernateProperties;
    private final HibernateProperties properties;

    @PostConstruct
    private void initialize() {
        hibernateProperties = properties;
    }

    private static Properties hibernateProperties() {
        Properties properties = new Properties();
        if (hibernateProperties.getDefaultBatchFetchSize().nonNull()) {
            properties.setProperty("hibernate.default_batch_fetch_size", hibernateProperties.getDefaultBatchFetchSize());
        }
        if (hibernateProperties.getQuery().nonNull() && hibernateProperties.getQuery().getFailOnPaginationOverCollectionFetch().nonNull()) {
            properties.setProperty("hibernate.query.fail_on_pagination_over_collection_fetch", hibernateProperties.getQuery().getFailOnPaginationOverCollectionFetch());
        }
        if (hibernateProperties.getShowSql().nonNull()) {
            properties.setProperty("hibernate.show_sql", hibernateProperties.getShowSql());
        }
        if (hibernateProperties.getFormatSql().nonNull()) {
            properties.setProperty("hibernate.format_sql", hibernateProperties.getFormatSql());
        }

        properties.setProperty("hibernate.hbm2ddl.auto", hibernateProperties.getHbm2ddl().getAuto());
        properties.setProperty("hibernate.use_sql_comments", hibernateProperties.getUseSqlComments());
        properties.setProperty("hibernate.dialect", hibernateProperties.getDialect());
        properties.setProperty("hibernate.physical_naming_strategy", hibernateProperties.getPhysicalNamingStrategy());

        return properties;
    }

    @Bean
    @Primary
    public LocalContainerEntityManagerFactoryBean consumerEntityManagerFactory(@Qualifier("consumerDataSource") DataSource dataSource) {
        LocalContainerEntityManagerFactoryBean factoryBean = new LocalContainerEntityManagerFactoryBean();
        HibernateJpaVendorAdapter hibernateJpaVendorAdapter = new HibernateJpaVendorAdapter();

        factoryBean.setDataSource(dataSource);
        factoryBean.setPersistenceUnitName("consumerEntityManager");
        factoryBean.setPackagesToScan("com.jd.domain");
        factoryBean.setJpaVendorAdapter(hibernateJpaVendorAdapter);
//        factoryBean.setJpaProperties();

        return factoryBean;
    }

    @Bean
    @Primary
    public PlatformTransactionManager consumeTransactionManager(@Qualifier("consumerEntityManagerFactory")
                                                                 EntityManagerFactory consumerEntityManagerFactory) {
        JpaTransactionManager jpaTransactionManager = new JpaTransactionManager();
        jpaTransactionManager.setEntityManagerFactory(consumerEntityManagerFactory);

        return jpaTransactionManager;
    }

    @Bean
    @Primary
    public PersistenceExceptionTranslationPostProcessor consumerExceptionTranslationPostProcessor() {
        return new PersistenceExceptionTranslationPostProcessor();
    }

}
