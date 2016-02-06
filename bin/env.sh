# SUBMARINE --------------------------------------------------------------------

export user="submarine"
export home="/submarine"
export etc="$home/etc"
export log="$home/log"
export run="$home/run"
export ssl="$home/ssl"
export www="$home/www"

# WP_DOMAIN --------------------------------------------------------------------

if [[ -z $WP_DOMAIN ]]; then
  echo "ERROR: WP_DOMAIN is not defined."
  exit 1
else
  if [[ $WP_PORT -eq "443" ]];
    then SCHEME=https
    else SCHEME=http
  fi
  export WP_DOMAIN=$(echo $WP_DOMAIN | cut -d, -f1)
  export WP_HOME=${SCHEME}://${WP_DOMAIN}
fi

# DB_HOST ----------------------------------------------------------------------

if [[ -z $DB_HOST ]]; then
  if dig mysql > /dev/null;
    then export DB_HOST=mysql
  else echo "ERROR: DB_HOST is not defined" && exit 1
  fi
fi

# DB_NAME ----------------------------------------------------------------------

if [[ -z $DB_NAME ]]; then
  if [[ -n $WP_DOMAIN ]];
    then export DB_NAME=`echo ${WP_DOMAIN//./_} | cut -c 1-16`
    else echo "ERROR: DB_NAME is not defined" && exit 1
  fi
fi

# DB_USER ----------------------------------------------------------------------

if [[ -z $DB_USER ]]; then
  if env | grep MYSQL_ROOT_PASSWORD > /dev/null;
    then export DB_USER=root
    else echo "ERROR: DB_USER is not defined" && exit 1
  fi
fi

# DB_PASSWORD ------------------------------------------------------------------

if [[ -z $DB_PASSWORD ]]; then
  if env | grep MYSQL_ROOT_PASSWORD > /dev/null;
    then export DB_PASSWORD=`env | grep MYSQL_ROOT_PASSWORD | head -n1 | cut -d= -f2`
    else echo "ERROR: DB_PASSWORD is not defined" && exit 1
  fi
fi
