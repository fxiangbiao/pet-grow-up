package com.petgrowup.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC configuration.
 * CORS is handled at the Spring Security level via SecurityConfig.corsConfigurationSource().
 */
@Configuration
public class WebConfig implements WebMvcConfigurer {
}
