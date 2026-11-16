package phly101.example.skillbit_backend.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import phly101.example.skillbit_backend.auth.config.AuthProperties;
import phly101.example.skillbit_backend.auth.domain.RefreshTokenEntity;
import phly101.example.skillbit_backend.auth.repository.RefreshTokenRepo;
import phly101.example.skillbit_backend.auth.service.RefreshTokenGenerator;
import phly101.example.skillbit_backend.auth.service.RefreshTokenService;
import phly101.example.skillbit_backend.auth.service.SHA256Hasher;

@ExtendWith(MockitoExtension.class)
class RefreshTokenServiceTest {

    private static final UUID USER_ID =
            UUID.fromString("123e4567-e89b-12d3-a456-426614174000");

    private static final String RAW_TOKEN = "raw-refresh-token";
    private static final String TOKEN_HASH = "hashed-refresh-token";

    private static final Duration LIFETIME = Duration.ofDays(7);

    private static final Instant NOW =
            Instant.parse("2026-11-16T10:00:00Z");

    private static final Clock CLOCK =
            Clock.fixed(NOW, ZoneOffset.UTC);

    @Mock
    private RefreshTokenRepo refreshTokenRepo;

    @Mock
    private RefreshTokenGenerator refreshTokenGenerator;

    @Mock
    private SHA256Hasher sha256Hasher;

    @Mock
    private AuthProperties authProperties;

    @Captor
    private ArgumentCaptor<RefreshTokenEntity> captor;

    private RefreshTokenService refreshTokenService;

    @BeforeEach
    void setUp() {
        refreshTokenService = new RefreshTokenService(
                refreshTokenRepo,
                refreshTokenGenerator,
                sha256Hasher,
                authProperties,
                CLOCK);
    }

    private void stubTokenIssuance() {
        when(refreshTokenGenerator.generate())
                .thenReturn(RAW_TOKEN);

        when(sha256Hasher.hash(RAW_TOKEN))
                .thenReturn(TOKEN_HASH);

        when(authProperties.refreshTokenLifetime())
                .thenReturn(LIFETIME);
    }

    @Nested
    class IssueTokenServiceTest {

        @Test
        void issueToken_returnsRawToken() {
            // Arrange
            stubTokenIssuance();

            // Act
            String result = refreshTokenService.issueToken(USER_ID);

            // Assert
            assertEquals(RAW_TOKEN, result);
        }

        @Test
        void issueToken_savesHashedToken() {
            // Arrange
            stubTokenIssuance();

            // Act
            refreshTokenService.issueToken(USER_ID);

            // Assert
            verify(refreshTokenRepo).save(captor.capture());

            RefreshTokenEntity savedEntity = captor.getValue();

            assertEquals(TOKEN_HASH, savedEntity.getTokenHash());
        }

        @Test
        void issueToken_createsEntityWithCorrectInitialState() {
            // Arrange
            stubTokenIssuance();

            // Act
            refreshTokenService.issueToken(USER_ID);

            // Assert
            verify(refreshTokenRepo).save(captor.capture());

            RefreshTokenEntity savedEntity = captor.getValue();

            assertEquals(USER_ID, savedEntity.getUserId());
            assertEquals(TOKEN_HASH, savedEntity.getTokenHash());
            assertEquals(NOW, savedEntity.getCreatedAt());
            assertEquals(
                    NOW.plus(LIFETIME),
                    savedEntity.getExpiresAt());

            assertFalse(savedEntity.isRevoked());
            assertNull(savedEntity.getReplacedById());
        }
    }
}