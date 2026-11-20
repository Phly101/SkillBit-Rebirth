package phly101.example.skillbit_backend.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

// AI-written (Claude), reviewed by Basel.
public record SignupRequest(
        @NotBlank @Email @Size(max = 256) String email,
        @NotBlank @Size(min = 8, max = 72) String password
) {

    // A record's default toString prints every field, which would put the password in logs.
    @Override
    public String toString() {
        return "SignupRequest[email=" + email + ", password=***]";
    }
}
