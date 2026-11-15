package phly101.example.skillbit_backend.auth.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;


import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@Validated 
@ConfigurationProperties(prefix = "app.auth")
public record AuthProperties(
    @NotBlank  @Size (min =32) String jwtSecret,
    @NotNull Duration accessTokenLifetime,
    @NotNull Duration refreshTokenLifetime
) {

    
}
