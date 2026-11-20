package phly101.example.skillbit_backend.auth.service;

import java.security.SecureRandom;

import org.springframework.stereotype.Component;

@Component 
public class OtpCodeGenerator {

    private  final SecureRandom secureRandom = new SecureRandom();

    public String generateOtp(){
        int code = secureRandom.nextInt(1_000_000);
        return String.format("%06d", code);

    }

}
