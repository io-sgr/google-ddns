FROM google/cloud-sdk:alpine
MAINTAINER SgrAlpha <admin@sgr.io>

ENV KEY_FILE=/credential

RUN set -ex && \
    apk --update add --no-cache \
        bind-tools \
        jq \
        dcron \
        rsync

COPY files /opt/google_ddns

RUN chmod 755 /opt/google_ddns/bin/google_ddns.sh && \
    chmod 644 /opt/google_ddns/conf/cron.d/update_dns && \
    touch /var/log/google_ddns.log

CMD crond -s /opt/google_ddns/conf/cron.d/ -b -L /var/log/google_ddns.log && tail -f /var/log/google_ddns.log
