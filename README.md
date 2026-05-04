# nginx-certbot

Nginx reverse proxy with automated Let's Encrypt SSL certificate issuance and renewal.

## Requirements

- Docker & Docker Compose

---

## Getting Started

### Step 1 — Clone the repository

```bash
git clone https://github.com/manhtai831/nginx-certbot.git nginx-certbot
cd nginx-certbot
```

### Step 3 — First-time setup & obtain SSL certificate

> On the first run there is no certificate yet, so **do not** create SSL server configs yet. Follow the steps below in order.

**3.1. Set your domains in `bin/generate.sh`**

Open `bin/generate.sh` and replace `example.com` with your domain. Add more `-d` flags for additional domains/subdomains:

```sh
-d yourdomain.com \
-d www.yourdomain.com \
```

**3.2. Start nginx**

```bash
docker compose up -d
```

At this point nginx runs in HTTP-only mode, serving only ACME challenge requests (`cert.conf`). All other HTTP traffic is redirected to HTTPS (which will work once the certificate is issued).

**3.3. Issue the certificate**

```bash
bash bin/generate.sh
```

Certbot uses the webroot method to validate your domain and stores the certificate under `data/certbot/conf/live/common/`.

---

### Step 4 — Add SSL server configs

Once the certificate exists, copy a template from `nginx/conf.d/templates/` into `nginx/conf.d/servers/` and edit it.

**Reverse proxy (dynamic app):**

```bash
cp nginx/conf.d/templates/dynamic.conf nginx/conf.d/servers/myapp.conf
```

Edit `nginx/conf.d/servers/myapp.conf`:

```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com;           # <-- your domain

    include /etc/nginx/conf.d/ssl.conf;
    include /etc/nginx/conf.d/deny.conf;

    location / {
        include /etc/nginx/conf.d/proxy.conf;
        proxy_pass http://api_servers;    # <-- points to your upstream
    }
}
```

> Also update `nginx/conf.d/upstream.conf` to point to your real backend:
> ```nginx
> upstream api_servers {
>     server 127.0.0.1:3000;   # <-- actual backend address:port
> }
> ```

**Static site / SPA:**

```bash
cp nginx/conf.d/templates/static.conf nginx/conf.d/servers/mysite.conf
```

Edit `nginx/conf.d/servers/mysite.conf`:

```nginx
server {
    listen 443 ssl;
    server_name yourdomain.com;            # <-- your domain

    include /etc/nginx/conf.d/ssl.conf;
    include /etc/nginx/conf.d/deny.conf;

    location / {
        root /usr/share/nginx/html/mysite; # <-- folder name under data/nginx/sites/
        try_files $uri $uri/ /index.html;
    }
}
```

Place your static files in `data/nginx/sites/mysite/`.

**Reload nginx to apply the new config:**

```bash
docker compose exec nginx nginx -t && docker compose exec nginx nginx -s reload
```

---

## Directory structure

```
.
├── bin/
│   └── generate.sh             # Script to issue / force-renew the certificate
├── data/
│   ├── certbot/
│   │   ├── conf/               # Let's Encrypt certificates (live/common/)
│   │   └── www/                # ACME challenge webroot
│   └── nginx/
│       ├── log/                # Access & error logs
│       └── sites/              # Static file root for each site
├── nginx/
│   ├── nginx.conf              # Main nginx config
│   ├── entrypoint.sh           # Auto-reloads nginx every 6 hours
│   └── conf.d/
│       ├── cert.conf           # HTTP: ACME challenge + redirect to HTTPS
│       ├── ssl.conf            # Shared SSL certificate paths
│       ├── proxy.conf          # Shared reverse proxy headers
│       ├── upstream.conf       # Upstream backend declaration
│       ├── deny.conf           # IP block list
│       ├── servers/            # Per-site/domain server blocks (*.conf)
│       └── templates/
│           ├── dynamic.conf    # Template: reverse proxy
│           └── static.conf     # Template: static site
└── docker-compose.yml
```

---

## Automatic certificate renewal

Nothing extra is needed. The `certbot` container runs in the background and attempts renewal every 12 hours. Nginx reloads its config every 6 hours to pick up renewed certificates.

---

## Blocking IPs

Open `nginx/conf.d/deny.conf` and add the IPs to block:

```nginx
deny 1.2.3.4;
deny 5.6.7.0/24;
```

Then reload nginx:

```bash
docker compose exec app_nginx nginx -s reload
```

## Change network
```
sed -i '' 's|nginx_certbot_default|nginx_certbot_default_new|g' docker-compose.yml
```

## Move ssl.conf to up
```
cp nginx/conf.d/templates/ssl.conf nginx/conf.d/ssl.conf 
```

## Create user basic auth
- Make create new user.
```
docker run --rm httpd:2.4-alpine htpasswd -nbB user2 pass2 >> nginx/conf.d/basic-auths/.htpasswd
```
- Enabled basic auth in `nginx/conf.d/basic-auth.conf`.
```
nano nginx/conf.d/basic-auth.conf
```

- Reload nginx.
```
docker compose exec nginx nginx -t && docker compose exec nginx nginx -s reload
```