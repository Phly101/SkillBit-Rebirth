package phly101.example.skillbit_backend.auth.service;

import java.security.SecureRandom;
import java.util.Base64;

import org.springframework.stereotype.Component;

@Component
public class RefreshTokenGenerator {
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int RANDOMN_TOKEN_BYTES = 64;

    public String generate() {

        byte[] keyBytes = new byte[RANDOMN_TOKEN_BYTES];
        RANDOM.nextBytes(keyBytes);

        String urlSafeToken = Base64.getUrlEncoder().withoutPadding().encodeToString(keyBytes);
        return urlSafeToken;
    }

}
