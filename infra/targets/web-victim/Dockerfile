FROM vulnerables/web-dvwa:latest

USER root

RUN set -eux; \
    printf 'deb [trusted=yes] http://archive.debian.org/debian stretch main\n' > /etc/apt/sources.list; \
    printf 'deb [trusted=yes] http://archive.debian.org/debian-security stretch/updates main\n' >> /etc/apt/sources.list; \
    printf 'Acquire::Check-Valid-Until "false";\n' > /etc/apt/apt.conf.d/99archive; \
    apt-get -o Acquire::Check-Valid-Until=false update; \
    apt-get install -y --allow-unauthenticated --no-install-recommends curl ca-certificates; \
    curl -fL \
      https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.0-1_amd64.deb \
      -o /tmp/wazuh-agent.deb; \
    dpkg -i /tmp/wazuh-agent.deb || true; \
    apt-get -f install -y --allow-unauthenticated; \
    test -x /var/ossec/bin/wazuh-control; \
    rm -f /tmp/wazuh-agent.deb; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY isolate-webapp.sh /var/ossec/active-response/bin/isolate-webapp
RUN chmod 750 /var/ossec/active-response/bin/isolate-webapp

ENTRYPOINT ["/entrypoint.sh"]
