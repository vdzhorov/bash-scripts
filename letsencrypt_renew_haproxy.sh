#!/bin/bash
# This script is used for HAproxy renewing Letsencrypt certificates ONLY. You must have issued your certificates beforehand.
# The certificates must be also included in your HAproxy config.
# If you wish to issue a new cert, you can use the following example command:

# sudo certbot certonly --standalone -d new.domain.com \
#     --non-interactive --agree-tos --email admin@example.com \
#     --http-01-port=8888

notofication_email='admin@mydomain.com'
certbot_bin='/usr/bin/certbot'
HA_PORT='8888'

run_certbot () {
        if [[ "$1" -ne '' ]]; then
                $certbot_bin renew --tls-sni-01-port=$HA_PORT $1
        else
                $certbot_bin renew --tls-sni-01-port=$HA_PORT
        fi
}

run_certbot --dry-run

if [ "$?" -ne 0 ]; then
        echo "<html>Dry run for Letsencrypt on $(hostname) returned exit status code $?. Please investigate why this happened</html>" | mail -s "Dry run for SSL Letsencrypt on $(hostname) did not succeed." $notofication_email
elif [ "$?" -eq 0 ]; then

        run_certbot

        for dir in /etc/letsencrypt/live/*; do
                dir_temp=$(echo $dir | cut -d'/' -f5)
                cat /etc/letsencrypt/live/$dir_temp/fullchain.pem /etc/letsencrypt/live/$dir_temp/privkey.pem > /etc/pki/tls/certs/$dir_temp.crt
        done
        pkill -f -9 haproxy && haproxy -f /etc/haproxy/haproxy.cfg
        echo "<html>Certificates on $(hostname) renewed successfully.</html>" | mail -s "Certificates on $(hostname) renewed successfully." $notofication_email                                 
fi
