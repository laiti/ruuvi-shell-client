FROM alpine
USER 1577:1577
WORKDIR /ruuvishell

# Install bash as it is not included in base alpine image
RUN apk add --no-cache bash

# Settings has a wildcard so it is copied only if it exists
COPY formatters ruuvi-shell-client.sh settings* /ruuvishell/
CMD ["./ruuvi-shell-client.sh"]