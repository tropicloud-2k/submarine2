#!/bin/bash

sleep $(shuf -i 3-10 -n 1)
source /wps/bin/env.sh

if [[ ! -f $home/.submarine ]]; then
  echo "=> Bootstraping $WP_DOMAIN"
  source /wps/bin/setup.sh
fi

if [[ -f $home/.bootstrap ]]; then
  echo "=> Waiting to join cluster"
  while [[ -f $home/.bootstrap ]]; do
    sleep 3
  done
fi

# RUN --------------------------------------------------------------------------

echo "=> Repairing permissions:"
chown -R $user:nginx $home
echo "=> Starting services"
exec su -l $user -c "s6-svscan $run"
