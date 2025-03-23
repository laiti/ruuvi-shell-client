FROM alpine
USER 1577:1577
WORKDIR /ruuvishell
COPY settings /ruuvishell/settings
CMD ["./ruuvi-shell-client.sh"]