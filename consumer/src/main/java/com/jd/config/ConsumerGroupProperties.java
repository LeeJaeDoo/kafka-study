package com.jd.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import lombok.Getter;
import lombok.Setter;

/**
 * @author Jaedoo Lee
 */
@Component
@Getter
@Setter
@ConfigurationProperties(prefix = "kafka.group-id")
public class ConsumerGroupProperties {

    private String test1;
    private String test2;

}
