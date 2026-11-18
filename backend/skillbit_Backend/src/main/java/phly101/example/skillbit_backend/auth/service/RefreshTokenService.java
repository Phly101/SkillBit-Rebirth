package phly101.example.skillbit_backend.auth.service;

import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

import org.springframework.stereotype.Service;

import jakarta.transaction.Transactional;
import phly101.example.skillbit_backend.auth.config.AuthProperties;
import phly101.example.skillbit_backend.auth.domain.RefreshTokenEntity;
import phly101.example.skillbit_backend.auth.dto.IssuedRefreshToken;
import phly101.example.skillbit_backend.auth.dto.TokenPair;
import phly101.example.skillbit_backend.auth.repository.RefreshTokenRepo;
import phly101.example.skillbit_backend.common.exceptions.ErrorCode;
import phly101.example.skillbit_backend.common.exceptions.UnauthorizedException;

@Service
public class RefreshTokenService {
    private final RefreshTokenRepo refreshTokenRepo;
    private final RefreshTokenGenerator refreshTokenGenerator;
    private final AccessTokenGenerator accessTokenGenerator;
    private final SHA256Hasher sha256Hasher;
    private final AuthProperties authProperties;
    private final Clock clock;

    public RefreshTokenService(RefreshTokenRepo refreshTokenRepo, RefreshTokenGenerator refreshTokenGenerator,
            AccessTokenGenerator accessTokenGenerator, SHA256Hasher sha256Hasher, AuthProperties authProperties,
            Clock clock) {
        this.refreshTokenRepo = refreshTokenRepo;
        this.refreshTokenGenerator = refreshTokenGenerator;
        this.accessTokenGenerator = accessTokenGenerator;
        this.sha256Hasher = sha256Hasher;
        this.authProperties = authProperties;
        this.clock = clock;
    }

    public IssuedRefreshToken issueToken(UUID userId) {
        String rawToken = refreshTokenGenerator.generate();
        String tokenHash = sha256Hasher.hash(rawToken);
        Instant now = Instant.now(clock);
        Instant expiresAt = now.plus(authProperties.refreshTokenLifetime());

        RefreshTokenEntity refreshToken = new RefreshTokenEntity(userId, tokenHash, now, expiresAt);
        refreshTokenRepo.save(refreshToken);
        return new IssuedRefreshToken(rawToken, refreshToken.getId());

    }

    @Transactional(dontRollbackOn = UnauthorizedException.class)
    public TokenPair rotate(String oldToken) {
        RefreshTokenEntity old = refreshTokenRepo
                .findByTokenHash(sha256Hasher.hash(oldToken))
                .orElseThrow(() -> new UnauthorizedException(
                        ErrorCode.REFRESH_TOKEN_INVALID, "Invalid refresh token"));
        // already rotated: someone is reusing a used-up token, so assume theft
        if (old.isRevoked() && old.getReplacedById() != null) {
            refreshTokenRepo.revokeAllActiveTokensByUserId(old.getUserId());
            throw new UnauthorizedException(ErrorCode.REFRESH_TOKEN_REUSED, "Refresh token reuse detected");

        }
        // revoked by logout
        if (old.isRevoked()) {
            throw new UnauthorizedException(
                    ErrorCode.REFRESH_TOKEN_INVALID, "Invalid refresh token");
        }
        // token expired
        if (old.getExpiresAt().isBefore(Instant.now(clock))) {
            throw new UnauthorizedException(
                    ErrorCode.REFRESH_TOKEN_EXPIRED, "Refresh token expired");
        }
        IssuedRefreshToken newToken = issueToken(old.getUserId());
        old.setReplacedById(newToken.id());
        old.setRevoked(true);

        String accessToken = accessTokenGenerator.createAccessToken(old.getUserId());
        return new TokenPair(accessToken, newToken.rawToken());

    }

@Transactional
public void logout(String rawToken) {
     String tokenHash = sha256Hasher.hash(rawToken);
    RefreshTokenEntity token =
            refreshTokenRepo.findByTokenHash(tokenHash).orElse(null);

    if (token == null) {
        return;
    }

    // Token was already rotated and is being reused.
    if (token.isRevoked() && token.getReplacedById() != null) {
        refreshTokenRepo.revokeAllActiveTokensByUserId(token.getUserId());
        return;
    }

    // Already revoked by logout. Nothing to do.
    if (token.isRevoked()) {
        return;
    }

    // Active or expired token.
    token.setRevoked(true);
}

}
