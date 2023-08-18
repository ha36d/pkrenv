ARG BASH_VERSION=5
FROM "docker.io/bash:${BASH_VERSION}"

# Runtime dependencies
RUN apk add --no-cache --purge \
    curl \
    ;

ARG PKRENV_VERSION=3.0.0
RUN wget -O /tmp/pkrenv.tar.gz "https://github.com/ha36d/pkrenv/archive/refs/tags/v${PKRENV_VERSION}.tar.gz" \
    && tar -C /tmp -xf /tmp/pkrenv.tar.gz \
    && mv "/tmp/pkrenv-${PKRENV_VERSION}/bin"/* /usr/local/bin/ \
    && mkdir -p /usr/local/lib/pkrenv \
    && mv "/tmp/pkrenv-${PKRENV_VERSION}/lib" /usr/local/lib/pkrenv/ \
    && mv "/tmp/pkrenv-${PKRENV_VERSION}/libexec" /usr/local/lib/pkrenv/ \
    && mkdir -p /usr/local/share/licenses \
    && mv "/tmp/pkrenv-${PKRENV_VERSION}/LICENSE" /usr/local/share/licenses/pkrenv \
    && rm -rf /tmp/pkrenv* \
    ;
ENV PKRENV_ROOT /usr/local/lib/pkrenv

ENV PKRENV_CONFIG_DIR /var/pkrenv
VOLUME /var/pkrenv

# Default to latest; user-specifiable
ENV PKRENV_PACKER_VERSION latest
ENTRYPOINT ["/usr/local/bin/packer"]
