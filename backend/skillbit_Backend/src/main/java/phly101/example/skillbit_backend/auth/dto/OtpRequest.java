package phly101.example.skillbit_backend.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

// AI-written (Claude), reviewed by Basel.
// Body of /auth/otp/send and /auth/otp/resend.
public record OtpRequest(
        @NotBlank @Email @Size(max = 256) String email,
        @NotNull OtpPurpose purpose
) {
}
