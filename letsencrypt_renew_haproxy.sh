#!/bin/bash
# This script is used for HAproxy renewing Letsencrypt certificates ONLY. You must have issued your certificates beforehand.
# The certificates must be also included in your HAproxy config.
# If you wish to issue a new cert, you can use the following example command:

# sudo certbot certonly --standalone -d new.domain.com \
#     --non-interactive --agree-tos --email admin@example.com \
#     --http-01-port=8888

GLOBIGNORE='*ca-bundle*'

NOTIFICATION_EMAIL='admin@mydomain.com'
CERTBOT_BIN='/usr/bin/certbot'
HA_PORT='8888'
CERT_DIR='/etc/pki/tls/certs/'
RENEW_DAYS='10'


get_days_exp() {
  local d1=$(date -d "`openssl x509 -in $1 -text -noout|grep "Not After"|cut -c 25-`" +%s)
  local d2=$(date -d "now" +%s)
  # Return result in global variable
  DAYS_EXP=$(echo \( $d1 - $d2 \) / 86400 |bc)
  echo $DAYS_EXP
}

run_certbot () {
  if [[ "$1" -ne '' ]]; then
    $CERTBOT_BIN renew -q --tls-sni-01-port=$HA_PORT $1
  else
    $CERTBOT_BIN renew -q --tls-sni-01-port=$HA_PORT
  fi
}

if ! run_certbot --dry-run; then
  echo "<html>Dry run for Letsencrypt on $(hostname) returned exit status code $?. Please investigate why this happened</html>" | mail -s "Dry run for SSL Letsencrypt on $(hostname) did not succeed." $NOTIFICATION_EMAIL
else

  for dir in /etc/pki/tls/certs/*.crt; do
    dir_temp=$(echo $dir | cut -d'/' -f6)
    IS_DUE_FOR_RENEWAL=$(get_days_exp "/etc/pki/tls/certs/$dir_temp")
    if [ "$IS_DUE_FOR_RENEWAL" -lt "$RENEW_DAYS" ]; then
       DUE_FOR_RENEWAL=1
    fi
  done

  if [[ "$DUE_FOR_RENEWAL" -eq 1 ]]; then
    run_certbot
    for dir in /etc/letsencrypt/live/*; do
      dir_temp=$(echo $dir | cut -d'/' -f5)
      cat /etc/letsencrypt/live/$dir_temp/fullchain.pem /etc/letsencrypt/live/$dir_temp/privkey.pem > /etc/pki/tls/certs/$dir_temp.crt
    done

  pkill -f -9 haproxy && haproxy -f /etc/haproxy/haproxy.cfg
  echo "<html>Certificates on $(hostname) renewed successfully.</html>" | mail -s "Certificates on $(hostname) renewed successfully." $NOTIFICATION_EMAIL
  fi
fi
