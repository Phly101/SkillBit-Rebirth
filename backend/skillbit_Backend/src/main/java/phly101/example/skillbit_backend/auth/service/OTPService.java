package phly101.example.skillbit_backend.auth.service;

import java.util.UUID;

import org.springframework.stereotype.Service;

import phly101.example.skillbit_backend.auth.dto.OtpPurpose;
import phly101.example.skillbit_backend.auth.dto.OtpSent;

@Service 
public class OTPService {



    public OtpSent sendOTP(UUID userId,OtpPurpose otpPurpose){
     return null;
    }

    
    public void verifyOTP(UUID userId, OtpPurpose otpPurpose,String otpCode){

    }

}
