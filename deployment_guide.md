# Guía de Despliegue Cronológica: ingles-facil.com

Siga este orden paso a paso para garantizar un despliegue "zero-touch" exitoso de su instancia de Cal.diy.

---

## Fase 1: Configuración de Google Cloud (Pre-requisitos)
Antes de tocar el código, necesitamos las llaves de acceso.

1.  **Crear Proyecto**: En [Google Cloud Console](https://console.cloud.google.com/), cree un proyecto llamado `Cal-Ingles-Facil`.
2.  **Habilitar API**: Busque y habilite la **Google Calendar API**.
3.  **Configurar Pantalla de Consentimiento OAuth**: Configure los datos básicos de su aplicación.
4.  **Crear Credenciales OAuth 2.0**:
    *   Tipo: Aplicación Web.
    *   **JavaScript Origins**: `https://ingles-facil.com`
    *   **Redirect URIs**: `https://ingles-facil.com/api/auth/callback/google`
    *   *Guarde el Client ID y Client Secret.*
5.  **Crear Service Account**:
    *   Vaya a IAM > Service Accounts.
    *   Cree una cuenta y genere una **llave JSON**.
    *   *Guarde el contenido de este JSON.*

---

## Fase 2: Preparación del Repositorio
1.  **Fork**: Haga un fork del repositorio oficial [calcom/cal.diy](https://github.com/calcom/cal.diy).
2.  **Añadir Archivos de Orquestación**: Suba los siguientes archivos (ya generados) a la raíz de su repositorio:
    *   `railway.json`
    *   `Dockerfile`
    *   `start.sh`
    *   `docker-compose.yml`

---

## Fase 3: Despliegue en Railway
1.  **Crear Proyecto**: En Railway, seleccione **New Project > Provision from GitHub** y elija su fork.
2.  **Aprovisionar Bases de Datos**:
    *   Haga clic en **New > Database > Add PostgreSQL**.
    *   Haga clic en **New > Database > Add Redis**.
3.  **Vincular Dominio**:
    *   En el servicio Web, vaya a **Settings > Domains**.
    *   Añada `ingles-facil.com`.
4.  **Configurar DNS**:
    *   En su proveedor de dominio, cree un registro **CNAME** que apunte a la dirección generada por Railway.

---

## Fase 4: Configuración de Variables de Entorno
Vaya a la pestaña **Variables** del servicio Web en Railway y pegue los valores del archivo `.env.example`:

| Variable | Valor |
| :--- | :--- |
| `NEXT_PUBLIC_WEBAPP_URL` | `https://ingles-facil.com` |
| `NEXTAUTH_URL` | `https://ingles-facil.com` |
| `NEXTAUTH_SECRET` | *(El hash de 32 bits generado)* |
| `CALENDSO_ENCRYPTION_KEY` | *(El hash de 24 bits generado)* |
| `GOOGLE_LOGIN_ENABLED` | `true` |
| `GOOGLE_API_CREDENTIALS` | *(El contenido del JSON de la Service Account)* |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` |

---

## Fase 5: Validación y Primer Inicio
1.  **Build automático**: Railway detectará los cambios y comenzará la construcción.
2.  **Sincronización de DB**: Observe los logs. El script `start.sh` ejecutará `npx prisma db push`.
3.  **Acceso**: Entre a `https://ingles-facil.com/auth/setup` para crear su usuario administrador.

---

## Fase 6: Integración con WordPress
1.  **Webhook en Cal.diy**: Vaya a Settings > Webhooks en su instancia de Cal.
2.  **Endpoint**: Apunte a `https://ingles-facil.com/wp-json/calcom/v1/booking`.
3.  **Eventos**: Seleccione `BOOKING_CREATED` y `BOOKING_CANCELLED` para notificar a su WordPress.
