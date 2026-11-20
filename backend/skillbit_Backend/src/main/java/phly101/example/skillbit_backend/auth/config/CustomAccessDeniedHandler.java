package phly101.example.skillbit_backend.auth.config;

import java.io.IOException;
import java.time.Instant;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import phly101.example.skillbit_backend.common.dto.SkillBitErrorResponse;
import phly101.example.skillbit_backend.common.exceptions.ErrorCode;
import tools.jackson.databind.ObjectMapper;

@Component
public class CustomAccessDeniedHandler implements AccessDeniedHandler {
    private static final Logger log = LoggerFactory.getLogger(CustomAccessDeniedHandler.class);
    private final ObjectMapper objectMapper;

    CustomAccessDeniedHandler(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
            AccessDeniedException accessDeniedException) throws IOException, ServletException {
        String traceId = UUID.randomUUID().toString();
        log.warn(
                "[{}] {} - {}",
                traceId,
                ErrorCode.FORBIDDEN,
                accessDeniedException.getMessage());

        SkillBitErrorResponse body = new SkillBitErrorResponse(
                HttpServletResponse.SC_FORBIDDEN,
                ErrorCode.FORBIDDEN.name(),
                "Access is denied.",
                Instant.now(),
                request.getRequestURI(),
                traceId,
                null);
        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        objectMapper.writeValue(response.getWriter(), body);

    }

}
