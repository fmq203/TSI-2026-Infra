# Host víctima de CU-02 (fuerza bruta SSH): OpenSSH + rsyslog + agente Wazuh.
# Imagen propia en vez de linuxserver/openssh-server (Alpine): en Debian el agente Wazuh
# se instala con el procedimiento oficial apt, el más documentado.
FROM debian:bookworm-slim

ARG WAZUH_VERSION=4.9.0-1

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openssh-server rsyslog iptables procps curl gnupg ca-certificates \
 && curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
      > /etc/apt/sources.list.d/wazuh.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends wazuh-agent=${WAZUH_VERSION} \
 && rm -rf /var/lib/apt/lists/*

# rsyslog en contenedor: sin acceso al log del kernel (imklog falla) y con timestamps
# tradicionales ("Oct  5 12:00:00 host sshd[1]: ...") que el predecoder de Wazuh
# reconoce sin dudas (Debian 12 cambió el default a ISO 8601 de alta precisión).
RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf \
 && echo '$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat' > /etc/rsyslog.d/00-traditional.conf

# sshd en 2222 (mismo puerto que la imagen anterior, así no cambian los docs), con
# contraseña habilitada a propósito: es el blanco de la fuerza bruta.
RUN printf '%s\n' 'Port 2222' 'PasswordAuthentication yes' 'PermitRootLogin no' 'SyslogFacility AUTH' 'LogLevel INFO' \
      > /etc/ssh/sshd_config.d/lab.conf

# El agente lee auth.log (el instalador no lo agrega porque en el build no existe).
RUN printf '%s\n' '<ossec_config>' '  <localfile>' '    <log_format>syslog</log_format>' \
      '    <location>/var/log/auth.log</location>' '  </localfile>' '</ossec_config>' \
      >> /var/ossec/etc/ossec.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 2222
ENTRYPOINT ["/entrypoint.sh"]
