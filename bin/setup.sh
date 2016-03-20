touch $home/.bootstrap

# DATABASE --------------------------------------------------------------------

MYSQL="mysql -u$DB_USER -p$DB_PASSWORD -h$DB_HOST"

echo "=> Waiting database connection"
while ! $MYSQL -sN -e "SHOW DATABASES" > /dev/null 2>&1; do
  ((c++)) && ((c==10)) && exit 1
  sleep 5
done

if ! $MYSQL -sN -e "SHOW DATABASES" | grep -o $DB_NAME > /dev/null; then
  echo "=> Creating database $DB_NAME"
  if $MYSQL -sN -e "CREATE DATABASE $DB_NAME";
    then echo "Database $DB_NAME created"
    else echo "ERROR: Database creation failed" && exit 1
  fi
fi

# SUBMARINE --------------------------------------------------------------------

[[ ! -f $acme/index.html ]] && curl -sL s3.tropicloud.net > $acme/index.html
[[ ! -d $log ]] && mkdir -p $log

if [[ ! -d $etc ]]; then
  cp -R /wps/etc $etc
  find $etc -type f -exec sed -i "s|example.com|$WP_DOMAIN|g" {} \;
fi

if [[ ! -d $run ]]; then
  cp -R /wps/run $run
  find $run -type f -exec chmod +x {} \;
fi

# SSL --------------------------------------------------------------------------

if [[ $WP_PORT -eq "443" ]]; then
  echo "=> Creating SSL certificates"

  [[ ! -d $ssl ]] && mkdir -p $ssl
  ACME_OPTIONS="--non-interactive --agree-tos"
  ln -sf $etc/nginx/https.conf $etc/nginx/conf.d/https.conf

  if [[ $@ == *'--test-cert'* ]]; then
    export ACME_OPTIONS="$ACME_OPTIONS --test-cert"
  fi

  if [[ $@ == *'--webroot'* ]]; then
    export ACME_OPTIONS="$ACME_OPTIONS --webroot -w $acme"
  elif [[ $@ == *'--standalone' ]]; then
    export ACME_OPTIONS="$ACME_OPTIONS --standalone"
  fi

  # create ssl certificates
  if letsencrypt certonly $ACME_OPTIONS -d $WP_DOMAIN -m $WP_MAIL; then
    cat /etc/letsencrypt/live/$WP_DOMAIN/fullchain.pem > $ssl/$WP_DOMAIN.crt
    cat /etc/letsencrypt/live/$WP_DOMAIN/privkey.pem > $ssl/$WP_DOMAIN.key
  # if letsencrypt fails, fallback to openssl
  else cd $ssl && curl -sL http://git.io/vmgTS | sh -s $WP_DOMAIN
  fi
fi

# WORDPRESS --------------------------------------------------------------------

if [[ ! -d $www ]]; then
  echo "=> Installing WordPress"

  # clone repository and check wp version
  git clone $WP_REPO $www && cd $www
  if [[ ! -z $WP_VERSION ]]; then
    cat composer.json \
    | jq '.require["johnpbloch/wordpress"]="'$WP_VERSION'"' \
    > composer.json && composer update
  fi && composer install

  # if required variables are set, install wordpress
  if [[ ! -z $WP_USER ]] && [[ ! -z $WP_PASS ]] && [[ ! -z $WP_MAIL ]]; then
    [[ -z $WP_TITLE ]] && export WP_TITLE="Submarine"
    [[ -z $DB_PREFIX ]] && export DB_PREFIX="`openssl rand -hex 3`_"
    wp core install \
    --url=$WP_HOME \
    --title=$WP_TITLE \
    --admin_name=$WP_USER \
    --admin_email=$WP_MAIL \
    --admin_password=$WP_PASS
  fi
fi

# ENV --------------------------------------------------------------------------

cat > $www/.env <<EOF
DB_HOST=$DB_HOST
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_PREFIX=$DB_PREFIX

WP_ENV=$WP_ENV
WP_PORT=$WP_PORT
WP_HOME=${SCHEME}://${WP_DOMAIN}
WP_SITEURL=${SCHEME}://${WP_DOMAIN}/wp

AUTH_KEY=$(openssl rand -hex 32)
SECURE_AUTH_KEY=$(openssl rand -hex 32)
LOGGED_IN_KEY=$(openssl rand -hex 32)
NONCE_KEY=$(openssl rand -hex 32)
AUTH_SALT=$(openssl rand -hex 32)
SECURE_AUTH_SALT=$(openssl rand -hex 32)
LOGGED_IN_SALT=$(openssl rand -hex 32)
NONCE_SALT=$(openssl rand -hex 32)
EOF

rm -f $home/.bootstrap
touch $home/.submarine
