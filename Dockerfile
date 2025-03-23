FROM alpine
WORKDIR /ruuvishell

# Install bash as it is not included in base alpine image. We need also jq and ncurses for tput.
RUN apk add --no-cache bash jq ncurses curl

# Settings has a wildcard so it is copied only if it exists
COPY ruuvi-shell-client.sh settings* /ruuvishell/
COPY formatters /ruuvishell/formatters

# tput wants that $TERM is set
ENV TERM=xterm

USER 1577:1577
CMD ["./ruuvi-shell-client.sh"]