package com.wearit;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;

@SpringBootApplication
@ComponentScan(basePackages = "com.wearit")
public class WearitApplication {

    public static void main(String[] args) {
        SpringApplication.run(WearitApplication.class, args);
    }

}