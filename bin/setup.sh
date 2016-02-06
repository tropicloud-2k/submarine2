touch $home/.bootstrap

# DATABASE --------------------------------------------------------------------

MYSQL="mysql -u$DB_USER -p$DB_PASSWORD -h$DB_HOST"

echo "=> Checking database connection"
if $MYSQL -sN -e "SHOW DATABASES" > /dev/null;
  then echo "Connection successful"
  else echo "Connection failed" && exit 1
fi

if ! $MYSQL -sN -e "SHOW DATABASES" | grep -o $DB_NAME > /dev/null; then
  echo "=> Creating database $DB_NAME"
  if $MYSQL -sN -e "CREATE DATABASE $DB_NAME";
    then echo "Database $DB_NAME created"
    else echo "ERROR: Database creation failed" && exit 1
  fi
fi

# SUBMARINE --------------------------------------------------------------------

if [[ ! -d $log ]]; then mkdir -p $log; fi
if [[ ! -d $etc ]]; then
  cp -R /wps/etc $etc
  find $etc -type f -exec sed -i "s|example.com|$WP_DOMAIN|g" {} \;
fi
if [[ ! -d $run ]]; then
  cp -R /wps/run $run
  find $run -type f -exec chmod +x {} \;
fi

# WORDPRESS --------------------------------------------------------------------

if [[ ! -d $www ]]; then
  echo "=> Installing WordPress"
  git clone $WP_REPO $www && cd $www
  if [[ ! -z $WP_VERSION ]]; then
    cat composer.json \
    | jq '.require["johnpbloch/wordpress"]="'$WP_VERSION'"' \
    > composer.json && composer update
  fi && composer install

  # if required variables are set, install wordpress
  if [[ -z $WP_TITLE ]]; then export WP_TITLE="Submarine"; fi
  if [[ -z $DB_PREFIX ]]; then export DB_PREFIX="`openssl rand -hex 3`_"; fi
  if [[ ! -z $WP_USER ]] && [[ ! -z $WP_PASS ]] && [[ ! -z $WP_MAIL ]]; then
    wp core install \
    --url=$WP_HOME \
    --title=$WP_TITLE \
    --admin_name=$WP_USER \
    --admin_email=$WP_MAIL \
    --admin_password=$WP_PASS
  fi
fi

# SSL --------------------------------------------------------------------------

if [[ $WP_PORT -eq "443" ]]; then
  if [[ $@ == *'--test-cert'* ]];
    then SSL_OPT="--agree-tos --test-cert"
    else SSL_OPT="--agree-tos"
  fi
  echo "=> Creating SSL certificates" && mkdir -p $ssl
  letsencrypt certonly -m $WP_MAIL -d $WP_DOMAIN $SSL_OPT
  ln -sf $etc/nginx/https.conf $etc/nginx/conf.d/https.conf
  cat /etc/letsencrypt/live/$WP_DOMAIN/*.pem > $ssl/$WP_DOMAIN.crt
  cat /etc/letsencrypt/live/$WP_DOMAIN/privkey.pem > $ssl/$WP_DOMAIN.key
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
EOF

rm -f $home/.bootstrap
touch $home/.submarine
