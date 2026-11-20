package phly101.example.skillbit_backend.auth;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.test.web.servlet.MockMvc;

import phly101.example.skillbit_backend.auth.constants.AuthConsts;
import phly101.example.skillbit_backend.auth.service.AccessTokenGenerator;

// AI-written (Claude), reviewed by Basel.
@SpringBootTest
@AutoConfigureMockMvc
class SecurityTokenTest {

    private static final String PROTECTED = "/api/v1/test/probe";
    private static final String PUBLIC_REFRESH = "/api/v1/auth/refresh";

    @Autowired
    private MockMvc mockMvc;
    @Autowired
    private JwtEncoder jwtEncoder;

    @Autowired
    private AccessTokenGenerator accessTokenGenerator;

    // ---- the four cases ----

    @Test
    void noToken_onProtectedPath_returns401Unauthorized() throws Exception {
        mockMvc.perform(get(PROTECTED))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
    }

    @Test
    void garbageToken_onProtectedPath_returns401Unauthorized() throws Exception {
        mockMvc.perform(get(PROTECTED)
                .header(HttpHeaders.AUTHORIZATION, "Bearer this.is.not-a-jwt"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
    }

    @Test
    void realToken_onProtectedPath_reachesTheEndpoint() throws Exception {
        String token = accessTokenGenerator.createAccessToken(UUID.randomUUID());

        mockMvc.perform(get(PROTECTED)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(content().string("ok"));
    }

    @Test
    void expiredToken_onPublicRefreshPath_isIgnored() throws Exception {
        String expired = expiredToken();

        // The request must get past security and reach the refresh logic,
        // so the error is about the refresh token, not about the access token.
        mockMvc.perform(post(PUBLIC_REFRESH)
                .header(HttpHeaders.AUTHORIZATION, "Bearer " + expired)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"refreshToken\":\"not-a-real-refresh-token\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value("REFRESH_TOKEN_INVALID"));
    }

    private String expiredToken() {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(AuthConsts.ISSUER)
                .issuedAt(now.minus(2, ChronoUnit.HOURS))
                .expiresAt(now.minus(1, ChronoUnit.HOURS))
                .subject(UUID.randomUUID().toString())
                .build();
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

}