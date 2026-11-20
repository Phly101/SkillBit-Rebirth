package phly101.example.skillbit_backend.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

// AI-written (Claude), reviewed by Basel.
public record VerifyOtpRequest(
        @NotBlank @Email @Size(max = 256) String email,
        @NotBlank @Pattern(regexp = "^[0-9]{6}$") String otp,
        @NotNull OtpPurpose purpose
) {

    // Keeps the code out of logs.
    @Override
    public String toString() {
        return "VerifyOtpRequest[email=" + email + ", otp=***, purpose=" + purpose + "]";
    }
}
