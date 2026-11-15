package phly101.example.skillbit_backend.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotEquals;

import org.junit.jupiter.api.Test;

import phly101.example.skillbit_backend.auth.service.SHA256Hasher;

class SHA256HasherTest {

    private static final String ABC_SHA256_HEX =
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";

    private final SHA256Hasher hasher = new SHA256Hasher();

    @Test
    void hash_shouldBeDeterministicForSameInput() {
        String firstHash = hasher.hash("refresh-token-1");
        String repeatedHash = hasher.hash("refresh-token-1");

        assertEquals(firstHash, repeatedHash);
    }

    @Test
    void hash_shouldDifferForDifferentInputs() {
        String firstHash = hasher.hash("refresh-token-1");
        String differentInputHash = hasher.hash("refresh-token-2");

        assertNotEquals(firstHash, differentInputHash);
    }

    @Test
    void hash_shouldProduce64HexChars() {
        String hash = hasher.hash("refresh-token-1");

        assertEquals(64, hash.length());
    }

    @Test
    void hash_shouldProduce64HexCharsForDifferentInputs() {
        String differentInputHash = hasher.hash("refresh-token-2");

        assertEquals(64, differentInputHash.length());
    }

    @Test
    void hash_shouldMatchKnownSha256TestVectorForAbc() {
        assertEquals(ABC_SHA256_HEX, hasher.hash("abc"));
    }
}