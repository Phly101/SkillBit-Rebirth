package phly101.example.skillbit_backend.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

import phly101.example.skillbit_backend.auth.service.RefreshTokenGenerator;

public class RefreshTokenGeneratorTest {
    private final RefreshTokenGenerator generator = new RefreshTokenGenerator();

    @Test
    void generatedTokens_shouldBeUnique() {
        String firstToken = generator.generate();
        String secondToken = generator.generate();

        assertNotEquals(firstToken, secondToken);
    }

    @Test
    void generatedToken_shouldHaveExpectedLength() {
        String token = generator.generate();

        assertEquals(86, token.length());
    }

    @Test
    void generatedToken_shouldBeUrlSafeWithoutPadding() {
        String token = generator.generate();

        assertTrue(token.matches("[A-Za-z0-9_-]+"), "Token must contain only Base64url characters");
        assertFalse(token.contains("="), "Token must not contain Base64 padding");
    }
}
