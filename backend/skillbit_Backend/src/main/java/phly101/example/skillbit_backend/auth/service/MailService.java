package phly101.example.skillbit_backend.auth.service;

import phly101.example.skillbit_backend.auth.dto.OtpPurpose;

public interface MailService {
     void sendOtp(String email, String code, OtpPurpose purpose);

}
