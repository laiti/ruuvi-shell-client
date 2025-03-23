FROM alpine
USER 1577:1577
WORKDIR /ruuvishell
COPY formatters /ruuvishell/formatters
COPY ruuvi-shell-client.sh /ruuvishell/ruuvi-shell-client.sh
COPY settings /ruuvishell/settings
CMD ["./ruuvi-shell-client.sh"]