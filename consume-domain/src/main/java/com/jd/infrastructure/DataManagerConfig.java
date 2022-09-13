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

import javax.persistence.EntityManagerFactory;
import javax.sql.DataSource;

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
public class DataManagerConfig {

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
