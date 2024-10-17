FROM alpine:latest

RUN apk add --no-cache jq curl

COPY update-domains.sh /usr/local/bin/update-domains.sh
COPY add-domain.sh /usr/local/bin/add-domain.sh

RUN chmod +x /usr/local/bin/update-domains.sh /usr/local/bin/add-domain.sh

ENTRYPOINT ["/bin/sh", "-c"]

CMD ["trap exit TERM; while :; do update-domains.sh; sleep 12h & wait $!; done"]
