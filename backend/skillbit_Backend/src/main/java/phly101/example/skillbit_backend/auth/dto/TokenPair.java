package phly101.example.skillbit_backend.auth.dto;

public record TokenPair(String accessToken, String refreshToken,long expiresInSeconds) {

}
