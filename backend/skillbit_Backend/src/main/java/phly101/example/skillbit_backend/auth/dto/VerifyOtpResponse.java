package phly101.example.skillbit_backend.auth.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

// AI-written (Claude), reviewed by Basel.
// Which fields are filled depends on the purpose; the others are left out of the JSON.
@JsonInclude(JsonInclude.Include.NON_NULL)
public record VerifyOtpResponse(
        TokenPair tokens,
        String resetToken,
        Boolean isNewUser
) {

    public static VerifyOtpResponse forSignup(TokenPair tokens) {
        return new VerifyOtpResponse(tokens, null, true);
    }

    public static VerifyOtpResponse forPasswordReset(String resetToken) {
        return new VerifyOtpResponse(null, resetToken, null);
    }

    public static VerifyOtpResponse forEmailChange() {
        return new VerifyOtpResponse(null, null, null);
    }
}
