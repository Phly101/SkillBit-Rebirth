package phly101.example.skillbit_backend.auth.service;

import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

import org.springframework.stereotype.Service;

import phly101.example.skillbit_backend.auth.config.AuthProperties;
import phly101.example.skillbit_backend.auth.domain.RefreshTokenEntity;
import phly101.example.skillbit_backend.auth.repository.RefreshTokenRepo;

@Service
public class RefreshTokenService {
    private final RefreshTokenRepo refreshTokenRepo;
    private final RefreshTokenGenerator refreshTokenGenerator;
    private final SHA256Hasher sha256Hasher;
    private final AuthProperties authProperties;
    private final Clock clock;

    public RefreshTokenService(RefreshTokenRepo refreshTokenRepo,RefreshTokenGenerator refreshTokenGenerator,
            SHA256Hasher sha256Hasher, AuthProperties authProperties, Clock clock) {
        this.refreshTokenRepo = refreshTokenRepo;
        this.refreshTokenGenerator = refreshTokenGenerator;
        this.sha256Hasher = sha256Hasher;
        this.authProperties = authProperties;
        this.clock = clock;
    }

    public String issueToken(UUID userId) {
        String rawToken = refreshTokenGenerator.generate();
        String tokenHash = sha256Hasher.hash(rawToken);
        Instant now = Instant.now(clock);
        Instant expiresAt = now.plus(authProperties.refreshTokenLifetime());

        RefreshTokenEntity refreshToken = new RefreshTokenEntity(userId, tokenHash,now, expiresAt);
        refreshTokenRepo.save(refreshToken);
        return rawToken;

    }

}
