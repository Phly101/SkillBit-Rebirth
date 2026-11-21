package phly101.example.skillbit_backend.auth.dto;

// AI-written (Claude), reviewed by Basel.
// Tells the app how many seconds to wait before it may ask for another code.
public record OtpSent(int resendAfterSeconds) {
}
