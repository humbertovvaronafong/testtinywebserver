# Tiny WebServer Docker Image

This Docker image provides a compact and efficient web server designed for simple deployments, custom configurations, and optional HTTPS support. It offers out-of-the-box features such as automatic certificate generation, time zone configuration, and HTTP to HTTPS redirection—all managed via environment variables for maximum flexibility.

## 🐳 How to Run

You can run the container in three different modes:

### 1. HTTP Mode (No HTTPS)

```bash
docker run -d --name testtinywebserver \
  -e TIMEZONE=America/Havana \
  -p 8080:80 \
  -v $(pwd)/config:/config \
  humbertovvaronafong/tiny-webserver
```

### 2. HTTPS Mode with Automatic Certificates (Let's Encrypt)

```bash
docker run -d --name testtinywebserver \
  -e TIMEZONE=America/Havana \
  -e REDIRECT_TO_HTTPS=yes \
  -e AUTOCERT=yes \
  -p 8443:443 \
  -v $(pwd)/config:/config \
  humbertovvaronafong/tiny-webserver
```

### 3. HTTPS Mode with Manual Certificates

```bash
docker run -d --name testtinywebserver \
  -e TIMEZONE=America/Havana \
  -e REDIRECT_TO_HTTPS=yes \
  -e AUTOCERT=no \
  -p 8443:443 \
  -v $(pwd)/config:/config \
  humbertovvaronafong/tiny-webserver
```

### 4. Docker Compose Example

You can also use Docker Compose to manage the container:

```
version: '3.8'
services:
  tinywebserver:
    image: humbertovvaronafong/tiny-webserver
    container_name: testtinywebserver
    ports:
      - "8080:80"
      - "8443:443"
    environment:
      - TIMEZONE=America/Havana
      - REDIRECT_TO_HTTPS=yes
      - AUTOCERT=yes
    volumes:
      - ./config:/config
    restart: unless-stopped
```

Start the service:

```bash
docker-compose up -d
```

## 🌐 Accessing the Web Server

Use your browser to access the server:

### HTTP Mode

```
http://192.168.1.4:8080/
```

### HTTPS Mode

```
https://192.168.1.4:8443/
```

## 🩺 Health Check

To inspect the container's health status:

```bash
docker inspect --format='{{json .State.Health}}' testtinywebserver | jq
```

## 📄 Logs

To view the logs from the container:

```bash
docker logs testtinywebserver
```

---

## ⚙️ Environment Variables

| Variable                 | Description                                                             | Default Value |
| ------------------------ | ----------------------------------------------------------------------- | ------------- |
| `TIMEZONE`               | Sets the system timezone inside the container.                          | `UTC`         |
| `NGINX_WORKER_PROCESSES` | Defines the number of worker processes for NGINX.                       | `auto`        |
| `REDIRECT_TO_HTTPS`      | Enables HTTP to HTTPS redirection (`yes` or `no`).                      | `no`          |
| `AUTOCERT`               | Enables automatic HTTPS certificates via Let's Encrypt (`yes` or `no`). | `no`          |
| `CERT_WARN_DAYS`         | Days before certificate expiration to trigger a renewal or warning.     | `30`          |

---

## 🔗 Repositories

- **GitHub Repository:** [https://github.com/humbertovvaronafong/tiny-webserver](https://github.com/humbertovvaronafong/tiny-webserver)
- **Zenodo Archive:** [https://zenodo.org/record/99999999](https://zenodo.org/record/99999999)

---

## 👤 Author

**Humberto Vinlay Varona-Fong**
📧 [hvinlay.varona@gmail.com](hvinlay.varona@gmail.com)

---

## 🪪 License

This project is licensed under the **Creative Commons Zero (CC0)** license.
You are free to use, modify, and distribute without restriction.
