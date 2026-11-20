package phly101.example.skillbit_backend.auth.config;

import java.util.List;

import org.jspecify.annotations.Nullable;
import org.springframework.security.oauth2.server.resource.web.BearerTokenResolver;
import org.springframework.security.oauth2.server.resource.web.DefaultBearerTokenResolver;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;

import jakarta.servlet.http.HttpServletRequest;

public class PublicPathBearerTokenResolver implements BearerTokenResolver {
    private final BearerTokenResolver delegate = new DefaultBearerTokenResolver();
    private final List<PathPatternRequestMatcher> publicMatchers;

    public PublicPathBearerTokenResolver(List<String> publicPaths) {
        this.publicMatchers = publicPaths.stream()
                .map(path -> PathPatternRequestMatcher.withDefaults().matcher(path))
                .toList();
    }

    @Override
    public @Nullable String resolve(HttpServletRequest request) {
        boolean isPublic = publicMatchers.stream().anyMatch(matcher -> matcher.matches(request));
        if (isPublic) {
            return null;
        } else {
            return delegate.resolve(request);
        }

    }

}
