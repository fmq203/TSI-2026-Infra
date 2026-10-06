FROM debian:12-slim

RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    curl -fLO https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.0-1_amd64.deb && \
    dpkg -i wazuh-agent_4.9.0-1_amd64.deb || apt-get install -f -y && \
    rm -f wazuh-agent_4.9.0-1_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash", "-c", "sed -i 's/MANAGER_IP/10.10.90.10/g' /var/ossec/etc/ossec.conf && if [ ! -s /var/ossec/etc/client.keys ]; then /var/ossec/bin/agent-auth -m 10.10.90.10 -A target-ssh-client; fi && /var/ossec/bin/wazuh-control start && tail -F /var/ossec/logs/ossec.log"]
