package phly101.example.skillbit_backend.auth.dto;

import java.util.UUID;

public record IssuedRefreshToken(String rawToken, UUID id) {

}
