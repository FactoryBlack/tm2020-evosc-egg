FROM alpine:3.18

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    git \
    unzip \
    netcat-openbsd \
    composer \
    php82 \
    php82-cli \
    php82-json \
    php82-mbstring \
    php82-curl \
    php82-xml \
    php82-mysqli \
    php82-pdo \
    php82-pdo_mysql \
    php82-zip \
    php82-opcache \
    xmlstarlet \
    jq

# Create PHP symlink
RUN ln -sf /usr/bin/php82 /usr/bin/php

# Create container user
RUN adduser -D -h /home/container container

# Set working directory
WORKDIR /home/container

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER container
EXPOSE 2350 5000

ENTRYPOINT ["/entrypoint.sh"]
