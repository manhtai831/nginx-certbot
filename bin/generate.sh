docker run --rm \
-v $(pwd)/data/certbot/conf:/etc/letsencrypt \
-v $(pwd)/data/certbot/www:/var/www/certbot \
certbot/certbot \
certonly \
-v \
--non-interactive \
--agree-tos  \
--force-renewal \
--email="" \
--webroot \
--webroot-path=/var/www/certbot \
--cert-name common \
-d  exam.net \