FROM certbot/certbot:v2.11.0

RUN apk add --no-cache jq

COPY get-certs.sh /usr/local/bin/get-certs.sh

RUN chmod +x /usr/local/bin/get-certs.sh

ENTRYPOINT ["/bin/sh", "-c"]

CMD ["trap exit TERM; while :; do certbot renew; sleep 12h & wait $!; done"]