# syntax=docker/dockerfile:1
# Community packaging for the official EffectCraft WebAssembly application.
# The WebAssembly build runs ONCE in GitHub Actions; this runtime stage only serves its output.
FROM nginx:1.28-alpine

ARG EFFECTCRAFT_COMMIT=unknown
ARG EFFECTCRAFT_VERSION=unknown

LABEL org.opencontainers.image.title="EffectCraft Web" \
      org.opencontainers.image.description="Community-maintained browser build of EffectCraft" \
      org.opencontainers.image.source="https://github.com/storytold/effectcraft" \
      org.opencontainers.image.url="https://github.com/MikaPST/effectcraft-web" \
      org.opencontainers.image.version="${EFFECTCRAFT_VERSION}" \
      org.opencontainers.image.revision="${EFFECTCRAFT_COMMIT}"

# Own the complete NGINX configuration; it is maintained in this repository.
COPY nginx.conf /etc/nginx/nginx.conf
COPY site/ /usr/share/nginx/html/
COPY legal/ /usr/share/nginx/html/licenses/

# All served files are readable by nginx; the unprivileged user needs no write access.
USER nginx
EXPOSE 8080
ENTRYPOINT []
CMD ["nginx", "-g", "daemon off;"]
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
