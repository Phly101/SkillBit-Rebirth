package phly101.example.skillbit_backend.auth.service;

import java.time.Instant;
import java.util.UUID;

import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import phly101.example.skillbit_backend.auth.config.AuthProperties;
import phly101.example.skillbit_backend.auth.constants.AuthConsts;

@Service
public class AccessTokenGenerator {
    private final AuthProperties authProperties;
    private final JwtEncoder jwtEncoder;

    public AccessTokenGenerator(AuthProperties authProperties, JwtEncoder jwtEncoder) {
        this.authProperties = authProperties;
        this.jwtEncoder = jwtEncoder;
    }

    public String createAccessToken(UUID userId) {
        var time = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(AuthConsts.issuer)
                .issuedAt(time)
                .expiresAt(time.plus(authProperties.accessTokenLifetime()))
                .subject(userId.toString())
                .build();

        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        Jwt jwt = jwtEncoder.encode(JwtEncoderParameters.from(header, claims));
        return jwt.getTokenValue();
    }
}