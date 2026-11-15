package phly101.example.skillbit_backend.auth.config;

import java.nio.charset.StandardCharsets;

import javax.crypto.spec.SecretKeySpec;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import com.nimbusds.jose.proc.SecurityContext;

@Configuration
public class JWTConfig {
    private final AuthProperties authProperties;

    public JWTConfig(AuthProperties authProperties) {
        this.authProperties = authProperties;
    }

    private SecretKeySpec getKey() {
        final String secret = authProperties.jwtSecret();
        byte[] secretBytes = secret.getBytes(StandardCharsets.UTF_8);
        return new SecretKeySpec(secretBytes, "HmacSHA256");
    }

    @Bean
    public JwtEncoder jwtEncoder() {
        SecretKeySpec keyspec = getKey();
        ImmutableSecret<SecurityContext> secretKey = new ImmutableSecret<>(keyspec);
        return new NimbusJwtEncoder(secretKey);
    }

    @Bean
    public JwtDecoder jwtDecoder() {
        SecretKeySpec keyspec = getKey();
        return NimbusJwtDecoder.withSecretKey(keyspec).macAlgorithm(MacAlgorithm.HS256).build();
    }

}
