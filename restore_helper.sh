#!/bin/bash

DB_USER=${DB_USER:-bacula}
DB_PASSWORD=${DB_PASSWORD:-bacula}
DB_NAME=${DB_NAME:-bacula}

DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-3306}

RESTORE_PATH=${RESTORE_PATH:-/srv/restore}
RESTORE_CLIENT=${RESTORE_CLIENT:$1}


[ -z $RESTORE_PATH ] && {
    echo "RESTORE_PATH not set"
    exit 0
}


[ -z $RESTORE_CLIENT ] && {
    echo "RESTORE_CLIENT not set"
    exit 0
}

query() {
    mysql -u$DB_USER -p$DB_PASSWORD -h $DB_HOST -P$DB_PORT $DB_NAME -N -e "$@"
    [ $? != 0 ] && {
        echo "MySQL didn't execute well, please check"
        exit 0
    }
}


# Determine viable clients from DB
clients=$(query "SELECT Client.Name FROM Client LEFT JOIN Job ON (Client.ClientId=Job.ClientId) WHERE Job.JobId IS NOT NULL GROUP BY Name;")
# Get restored clients
restored=$(ls -1 "$RESTORE_PATH" | tr '\n' '|' | sed 's#|$##g')

# Determine which node are not restored until now
left=$(echo "$clients" | egrep -v $restored)

case $1 in
    restore)
        python restore.py $2 $RESTORE_PATH/$2 --restoreclient=$RESTORE_CLIENT
    ;;
    *)
        echo "$left"
    ;;
esac
