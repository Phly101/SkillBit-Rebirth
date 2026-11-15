package phly101.example.skillbit_backend.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.BadJwtException;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwtValidationException;

import phly101.example.skillbit_backend.auth.config.AuthProperties;
import phly101.example.skillbit_backend.auth.config.JWTConfig;
import phly101.example.skillbit_backend.auth.constants.AuthConsts;
import phly101.example.skillbit_backend.auth.service.AccessTokenService;

class JwtTokenTest {

    private static final String SECRET = "some-test-secret-that-is-at-least-32-characters-long";
    private static final String OTHER_SECRET = "another-test-secret-that-is-at-least-32-characters-long";
    private static final UUID USER_ID = UUID.fromString("123e4567-e89b-12d3-a456-426614174000");

    private JWTConfig jwtConfig;
    private AccessTokenService tokenService;

    private AccessTokenService serviceWith(AuthProperties properties) {
        JWTConfig config = new JWTConfig(properties);
        return new AccessTokenService(properties, config.jwtEncoder());
    }

    @BeforeEach
    void setUp() {
        AuthProperties properties = new AuthProperties(
                SECRET, Duration.ofMinutes(15), Duration.ofDays(30));
        jwtConfig = new JWTConfig(properties);
        tokenService = serviceWith(properties);
    }

    @Test
    void serviceCreatesTokenTheDecoderAccepts() {
        String token = tokenService.createAccessToken(USER_ID);

        Jwt jwt = jwtConfig.jwtDecoder().decode(token);

        assertEquals(USER_ID.toString(), jwt.getSubject());
        assertEquals(AuthConsts.issuer, jwt.getClaimAsString("iss"));
        assertEquals(MacAlgorithm.HS256.getName(), jwt.getHeaders().get("alg"));
        assertEquals(Duration.ofMinutes(15),
                Duration.between(jwt.getIssuedAt(), jwt.getExpiresAt()));
    }

    @Test
    void decoderRejectsTokenSignedWithWrongSecret() {
        AuthProperties otherProperties = new AuthProperties(
                OTHER_SECRET, Duration.ofMinutes(15), Duration.ofDays(30));
        String token = serviceWith(otherProperties).createAccessToken(USER_ID);
        JwtDecoder decoder = jwtConfig.jwtDecoder();

        BadJwtException ex = assertThrows(BadJwtException.class, () -> decoder.decode(token));

        assertFalse(ex instanceof JwtValidationException);
    }

    @Test
    void decoderRejectsExpiredToken() {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(AuthConsts.issuer)
                .issuedAt(now.minus(Duration.ofMinutes(10)))
                .expiresAt(now.minus(Duration.ofMinutes(5)))
                .subject(USER_ID.toString())
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        String token = jwtConfig.jwtEncoder()
                .encode(JwtEncoderParameters.from(header, claims))
                .getTokenValue();
        JwtDecoder decoder = jwtConfig.jwtDecoder();

        assertThrows(JwtValidationException.class, () -> decoder.decode(token));
    }
}