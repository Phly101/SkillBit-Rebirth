package phly101.example.skillbit_backend.auth.config;

import java.io.IOException;
import java.time.Instant;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import phly101.example.skillbit_backend.common.dto.SkillBitErrorResponse;
import phly101.example.skillbit_backend.common.exceptions.ErrorCode;
import tools.jackson.databind.ObjectMapper;

@Component 
public class CustomAuthenticationEntryPoint implements AuthenticationEntryPoint {
    private static final Logger log = LoggerFactory.getLogger(CustomAuthenticationEntryPoint.class);

    private final ObjectMapper objectMapper;

    public CustomAuthenticationEntryPoint(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
            AuthenticationException authException) throws IOException, ServletException {
        String traceId = UUID.randomUUID().toString();

        log.warn(
                "[{}] {} - {}",
                traceId,
                ErrorCode.UNAUTHORIZED,
                authException.getMessage());

        SkillBitErrorResponse body = new SkillBitErrorResponse(
                HttpServletResponse.SC_UNAUTHORIZED,
                ErrorCode.UNAUTHORIZED.name(),
                "Authentication is required.",
                Instant.now(),
                request.getRequestURI(),
                traceId,
                null);
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        objectMapper.writeValue(response.getWriter(), body);

    }

}
