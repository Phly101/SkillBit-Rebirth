package phly101.example.skillbit_backend.auth;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// AI-written (Claude), reviewed by Basel.
// Test-only endpoint so the security tests have a protected path that always exists.
// Lives in src/test, so it never ships with the app.
@RestController
class SecurityProbeController {

    @GetMapping("/api/v1/test/probe")
    String probe() {
        return "ok";
    }
}