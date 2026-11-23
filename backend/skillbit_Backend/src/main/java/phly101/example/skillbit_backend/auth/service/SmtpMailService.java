package phly101.example.skillbit_backend.auth.service;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import phly101.example.skillbit_backend.auth.dto.OtpPurpose;

@Component
@Profile("prod") 
public class SmtpMailService implements MailService{

    @Override
    public void sendOtp(String email, String code, OtpPurpose purpose) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("Unimplemented method 'sendOTp'");
    }

}
