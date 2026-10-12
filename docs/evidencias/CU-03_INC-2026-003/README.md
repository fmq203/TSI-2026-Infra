# Evidencia CU-03 – Webshell + FIM + aislamiento automático
## INC-2026-003

### Objetivo

Demostrar que un archivo PHP sospechoso agregado al webroot de la aplicación es detectado por Wazuh mediante FIM y que, a partir de una regla específica de CU-03, se ejecuta automáticamente un Active Response que aísla el servidor afectado manteniendo la comunicación con el Wazuh Manager.

---

## Escenario

- Aplicación: `target-webapp`
- IP del webapp: `10.10.10.10`
- Agente Wazuh: `ID 003 - webapp`
- Directorio monitoreado por FIM: `/var/www/html`
- Archivo de prueba: `/var/www/html/cu03-isolation-test.php`
- Regla base FIM: `554`
- Regla local CU-03: `100200`
- Nivel de alerta CU-03: `12`
- Active Response: `isolate-webapp`
- Wazuh Manager: `10.10.90.10`
- Puerto preservado hacia Wazuh: `1514/TCP`
- Tiempo de aislamiento configurado: `600` segundos

---

## 1. FIM sobre el webroot

Se configuró el agente Wazuh del servidor web para monitorear en tiempo real:

```xml
<directories realtime="yes" check_all="yes">/var/www/html</directories>
```

El agente confirmó que `/var/www/html` quedó bajo monitoreo de integridad.

**Evidencia:** `01_fim_configurado_webroot.png`

---

## 2. Detección inicial del archivo PHP

Se creó un archivo PHP de prueba dentro del webroot para simular la aparición de un posible webshell.

Ejemplo:

```bash
docker exec target-webapp bash -c 'echo "<?php echo \"CU03 prueba\"; ?>" > /var/www/html/cu03-webshell-test.php'
```

Wazuh detectó la creación mediante FIM con la regla base:

- Regla: `554`
- Descripción: `File added to the system.`
- Agente: `webapp`
- Ruta detectada: `/var/www/html/cu03-webshell-test.php`

**Evidencia:** `02_fim_detecta_archivo_php.png`

---

## 3. Regla específica CU-03

Se agregó una regla local para elevar la detección cuando se agrega un archivo `.php` al webroot:

```xml
<group name="local,syscheck,cu03,">
  <rule id="100200" level="12">
    <if_sid>554</if_sid>
    <field name="file" type="pcre2">^/var/www/html/.*\.php$</field>
    <description>CU-03 Webshell: archivo PHP agregado al webroot: $(file)</description>
    <mitre>
      <id>T1505.003</id>
    </mitre>
  </rule>
</group>
```

La regla `100200` fue disparada correctamente con nivel 12.

**Evidencia:** `03_regla_cu03_100200_nivel12.png`

---

## 4. Active Response de aislamiento

Se creó el script:

```text
/var/ossec/active-response/bin/isolate-webapp
```

y se vinculó a la regla `100200`.

Configuración aplicada en el Wazuh Manager:

```xml
<command>
  <name>isolate-webapp</name>
  <executable>isolate-webapp</executable>
  <timeout_allowed>yes</timeout_allowed>
</command>

<active-response>
  <command>isolate-webapp</command>
  <location>local</location>
  <rules_id>100200</rules_id>
  <timeout>600</timeout>
</active-response>
```

**Evidencias:**
- `04_agente_webapp_y_script_aislamiento.png`
- `05_active_response_cu03_configurado.png`

---

## 5. Prueba final

Se creó un nuevo archivo para generar una alerta limpia:

```bash
docker exec target-webapp bash -c 'echo "<?php echo \"CU03 AISLAMIENTO\"; ?>" > /var/www/html/cu03-isolation-test.php'
```

Wazuh generó:

- Regla: `100200`
- Nivel: `12`
- Agente: `webapp`
- Archivo: `/var/www/html/cu03-isolation-test.php`

**Evidencia:** `06_alerta_final_cu03.png`

---

## 6. Ejecución del aislamiento

El log de Active Response confirmó:

```text
CU03 isolate-webapp: Starting isolation
CU03 isolate-webapp: Webapp isolated, Wazuh access preserved
```

**Evidencia:** `07_active_response_aislamiento.png`

---

## 7. Verificación del aislamiento

Luego del Active Response, la ruta por defecto dejó de existir y quedó únicamente la red local más una ruta específica hacia el Wazuh Manager:

```text
10.10.10.0/24 dev eth0 ...
10.10.90.10 via 10.10.10.254 dev eth0
```

Además, el acceso hacia otro segmento quedó bloqueado:

```text
ping: sendto: Network is unreachable
```

Esto demuestra que el webapp quedó aislado de otras redes.

**Evidencia:** `08_rutas_webapp_aislado.png`

---

## 8. Comunicación con Wazuh preservada

Durante el aislamiento, el agente continuó figurando como activo:

```text
ID: 003, Name: webapp, IP: any, Active
```

y se verificó conectividad al puerto utilizado por el agente:

```text
WAZUH 1514 OK
```

Por lo tanto, el aislamiento no eliminó la capacidad de monitoreo y reporte hacia el SIEM.

**Evidencias:**
- `09_agente_webapp_activo_durante_aislamiento.png`
- `10_wazuh_1514_preservado.png`

---

# Resultado

CU-03 quedó validado de punta a punta:

```text
Archivo PHP sospechoso
        ↓
FIM / syscheck
        ↓
Regla base 554
        ↓
Regla CU-03 100200 - nivel 12
        ↓
Active Response isolate-webapp
        ↓
Eliminación de ruta por defecto
        ↓
Servidor web aislado
        ↓
Comunicación con Wazuh preservada por TCP 1514
```

**Estado: COMPLETADO Y VERIFICADO.**

La respuesta está configurada con `timeout=600`, por lo que el aislamiento es temporal y la conectividad debe restaurarse al finalizar el período configurado.
