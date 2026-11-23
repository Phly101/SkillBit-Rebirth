package phly101.example.skillbit_backend.auth.service;

import java.util.List;
import java.util.Optional;
import java.util.concurrent.CopyOnWriteArrayList;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

import phly101.example.skillbit_backend.auth.dto.OtpPurpose;

@Service
@Profile({ "dev", "test" })
public class FakeMailService implements MailService {

    
    private final List<SentMail> sentMails = new CopyOnWriteArrayList<>();

    @Override
    public void sendOtp(String email, String code, OtpPurpose purpose) {
        final Logger log = LoggerFactory.getLogger(FakeMailService.class);
    log.atWarn()
       .log("[FAKE MAIL] OTP sent to {} for {}: {}", email, purpose, code);
        sentMails.add(new SentMail(email, purpose, code));
    }

    public Optional<String> getMostRecentCode(
            String email,
            OtpPurpose purpose) {
        for (int i = sentMails.size() - 1; i >= 0; i--) {
            SentMail mail = sentMails.get(i);

            if (mail.email().equals(email) && mail.purpose() == purpose) {
                return Optional.of(mail.code());
            }
        }

        return Optional.empty();
    }

    public List<SentMail> getSentMails() {
        return List.copyOf(sentMails);
    }

    public record SentMail(
            String email,
            OtpPurpose purpose,
            String code) {
    }

}