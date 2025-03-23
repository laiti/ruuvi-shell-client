FROM alpine
USER 1577:1577
WORKDIR /ruuvishell
CMD ["./ruuvi-shell-client.sh"]