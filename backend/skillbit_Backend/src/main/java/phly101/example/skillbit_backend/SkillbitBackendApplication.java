package phly101.example.skillbit_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@ConfigurationPropertiesScan 
@SpringBootApplication
public class SkillbitBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(SkillbitBackendApplication.class, args);
    }

}
