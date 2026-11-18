package phly101.example.skillbit_backend.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import phly101.example.skillbit_backend.auth.config.AuthProperties;
import phly101.example.skillbit_backend.auth.domain.RefreshTokenEntity;
import phly101.example.skillbit_backend.auth.dto.IssuedRefreshToken;
import phly101.example.skillbit_backend.auth.dto.TokenPair;
import phly101.example.skillbit_backend.auth.repository.RefreshTokenRepo;
import phly101.example.skillbit_backend.auth.service.AccessTokenGenerator;
import phly101.example.skillbit_backend.auth.service.RefreshTokenGenerator;
import phly101.example.skillbit_backend.auth.service.RefreshTokenService;
import phly101.example.skillbit_backend.auth.service.SHA256Hasher;
import phly101.example.skillbit_backend.common.exceptions.ErrorCode;
import phly101.example.skillbit_backend.common.exceptions.UnauthorizedException;

@ExtendWith(MockitoExtension.class)
class RefreshTokenServiceTest {

        private static final UUID USER_ID = UUID.fromString("123e4567-e89b-12d3-a456-426614174000");
        private static final UUID NEW_TOKEN_ID = UUID.fromString("223e4567-e89b-12d3-a456-426614174999");

        private static final String RAW_TOKEN = "raw-refresh-token";
        private static final String TOKEN_HASH = "hashed-refresh-token";

        private static final Duration LIFETIME = Duration.ofDays(7);

        private static final Instant NOW = Instant.parse("2026-11-16T10:00:00Z");

        private static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);
        private static final String OLD_RAW_TOKEN = "old-raw-refresh-token";
        private static final String OLD_TOKEN_HASH = "old-hashed-refresh-token";
        private static final String ACCESS_TOKEN = "new-access-token";

        @Mock
        private RefreshTokenRepo refreshTokenRepo;

        @Mock
        private RefreshTokenGenerator refreshTokenGenerator;

        @Mock
        private SHA256Hasher sha256Hasher;

        @Mock
        private AuthProperties authProperties;

        @Mock
        private AccessTokenGenerator accessTokenGenerator;

        @Captor
        private ArgumentCaptor<RefreshTokenEntity> captor;

        private RefreshTokenService refreshTokenService;

        @BeforeEach
        void setUp() {
                refreshTokenService = new RefreshTokenService(
                                refreshTokenRepo,
                                refreshTokenGenerator,
                                accessTokenGenerator,
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

        private RefreshTokenEntity oldToken(Instant expiresAt, boolean revoked, UUID replacedByID) {
                RefreshTokenEntity entity = new RefreshTokenEntity(USER_ID, TOKEN_HASH, NOW, expiresAt);
                entity.setReplacedById(replacedByID);
                entity.setRevoked(revoked);
                return entity;
        }

        private void stubOldTokenLookup(RefreshTokenEntity entity) {
                when(sha256Hasher.hash(OLD_RAW_TOKEN)).thenReturn(OLD_TOKEN_HASH);
                when(refreshTokenRepo.findByTokenHash(OLD_TOKEN_HASH)).thenReturn(Optional.of(entity));
        }

        private void stubSaveAssigningId() {
                when(refreshTokenRepo.save(any())).thenAnswer(invocation -> {
                        RefreshTokenEntity entity = invocation.getArgument(0);
                        ReflectionTestUtils.setField(entity, "id", NEW_TOKEN_ID);
                        return entity;
                });
        }

        @Nested
        class IssueTokenServiceTest {

                @Test
                void issueToken_returnsRawToken() {
                        // Arrange
                        stubTokenIssuance();

                        // Act
                        IssuedRefreshToken result = refreshTokenService.issueToken(USER_ID);

                        // Assert
                        assertEquals(RAW_TOKEN, result.rawToken());
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

        @Nested
        class RotateTest {
                @Test
                void rotate_unknownToken_throwsInvalid() {
                        // Arrange
                        when(sha256Hasher.hash(OLD_RAW_TOKEN)).thenReturn(OLD_TOKEN_HASH);
                        when(refreshTokenRepo.findByTokenHash(OLD_TOKEN_HASH)).thenReturn(Optional.empty());
                        // Act
                        UnauthorizedException ex = assertThrows(UnauthorizedException.class,
                                        () -> refreshTokenService.rotate(OLD_RAW_TOKEN));
                        // Assert
                        assertEquals(ErrorCode.REFRESH_TOKEN_INVALID, ex.getErrorCode());
                }

                @Test
                void rotate_expiredToken_throwsExpired() {
                        // Arrange
                        stubOldTokenLookup(oldToken(NOW.minusSeconds(1), false, null));
                        // Act
                        UnauthorizedException ex = assertThrows(UnauthorizedException.class,
                                        () -> refreshTokenService.rotate(OLD_RAW_TOKEN));
                        // Assert
                        assertEquals(ErrorCode.REFRESH_TOKEN_EXPIRED, ex.getErrorCode());
                        verify(refreshTokenRepo, never()).save(any());
                }

                @Test
                void rotate_revokedByLogout_throwsInvalid_WithoutRevokingEverything() {
                        // Arrange
                        stubOldTokenLookup(oldToken(NOW.plus(LIFETIME), true, null));
                        // Act
                        UnauthorizedException ex = assertThrows(UnauthorizedException.class,
                                        () -> refreshTokenService.rotate(OLD_RAW_TOKEN));
                        // Assert
                        assertEquals(ErrorCode.REFRESH_TOKEN_INVALID, ex.getErrorCode());
                        verify(refreshTokenRepo, never()).revokeAllActiveTokensByUserId(any());
                        verify(refreshTokenRepo, never()).save(any());
                }

                // AI Generated with claude and reviewed by Basel(Me)
                @Test
                void rotate_alreadyRotatedToken_revokesAllUserTokensAndThrowsReused() {
                        // Arrange
                        stubOldTokenLookup(oldToken(NOW.plus(LIFETIME), true, UUID.randomUUID()));
                        // Act
                        UnauthorizedException ex = assertThrows(UnauthorizedException.class,
                                        () -> refreshTokenService.rotate(OLD_RAW_TOKEN));
                        // Assert
                        assertEquals(ErrorCode.REFRESH_TOKEN_REUSED, ex.getErrorCode());
                        verify(refreshTokenRepo).revokeAllActiveTokensByUserId(USER_ID);
                        verify(refreshTokenRepo, never()).save(any());
                }

                @Test
                void rotate_activeToken_revokesOldAndLinksItToNew() {
                        // Arrange
                        RefreshTokenEntity old = oldToken(NOW.plus(LIFETIME), false, null);
                        stubOldTokenLookup(old);
                        stubTokenIssuance();
                        stubSaveAssigningId();
                        when(accessTokenGenerator.createAccessToken(USER_ID)).thenReturn(ACCESS_TOKEN);

                        // Act
                        refreshTokenService.rotate(OLD_RAW_TOKEN);

                        // Assert
                        verify(refreshTokenRepo).save(captor.capture());
                        RefreshTokenEntity newEntity = captor.getValue();

                        assertTrue(old.isRevoked());
                        assertEquals(NEW_TOKEN_ID, old.getReplacedById());
                        assertFalse(newEntity.isRevoked());
                }

                @Test
                void rotate_activeToken_returnsBothNewTokens() {
                        stubOldTokenLookup(oldToken(NOW.plus(LIFETIME), false, null));
                        stubTokenIssuance();
                        stubSaveAssigningId();
                        when(accessTokenGenerator.createAccessToken(USER_ID)).thenReturn(ACCESS_TOKEN);

                        TokenPair result = refreshTokenService.rotate(OLD_RAW_TOKEN);

                        assertEquals(ACCESS_TOKEN, result.accessToken());
                        assertEquals(RAW_TOKEN, result.refreshToken());
                }
        }

        @Nested
        class LogoutTest {

                @Test
                void logout_doesNothing_whenTokenIsNotFound() {
                       // Arrange{
                        when(sha256Hasher.hash(OLD_RAW_TOKEN)).thenReturn(OLD_TOKEN_HASH);
                        when(refreshTokenRepo.findByTokenHash(OLD_TOKEN_HASH)).thenReturn(Optional.empty());

                        // Act
                        refreshTokenService.logout(OLD_RAW_TOKEN);

                        // Assert
                        verify(refreshTokenRepo, never()).revokeAllActiveTokensByUserId(any());
                        verify(refreshTokenRepo,never()).save(any());
                }

                @Test
                void logout_revokesActiveToken() {
                        // Arrange
                        RefreshTokenEntity token = oldToken(NOW.plus(LIFETIME), false, null);

                        stubOldTokenLookup(token);

                        // Act
                        refreshTokenService.logout(OLD_RAW_TOKEN);

                        // Assert
                        assertTrue(token.isRevoked());
                        verify(refreshTokenRepo, never()).revokeAllActiveTokensByUserId(any());
                }

                @Test
                void logout_revokesExpiredToken() {
                        // Arrange
                        RefreshTokenEntity token = oldToken(NOW.minus(LIFETIME), false, null);
                        stubOldTokenLookup(token);

                        // Act
                        refreshTokenService.logout(OLD_RAW_TOKEN);

                        // Assert
                        assertTrue(token.isRevoked());
                        verify(refreshTokenRepo, never()).revokeAllActiveTokensByUserId(any());
                }

                @Test
                void logout_doesNothing_whenTokenWasAlreadyRevokedByLogout() {
                        // Arrange
                        RefreshTokenEntity token = oldToken(NOW.plus(LIFETIME), true, null);

                        stubOldTokenLookup(token);

                        // Act
                        refreshTokenService.logout(OLD_RAW_TOKEN);

                        // Assert
                        assertTrue(token.isRevoked());
                        assertNull(token.getReplacedById());

                        verify(refreshTokenRepo, never())
                                        .revokeAllActiveTokensByUserId(any());
                }

                @Test
                void logout_revokesAllActiveTokens_whenTokenWasAlreadyRotated() {
                        // Arrange
                        UUID replacementTokenId = UUID.randomUUID();

                        RefreshTokenEntity token = oldToken(NOW.plus(LIFETIME), true, replacementTokenId);

                        stubOldTokenLookup(token);

                        // Act
                        refreshTokenService.logout(OLD_RAW_TOKEN);

                        // Assert
                        assertTrue(token.isRevoked());
                        assertEquals(replacementTokenId, token.getReplacedById());

                        verify(refreshTokenRepo)
                                        .revokeAllActiveTokensByUserId(USER_ID);
                }

        }
}