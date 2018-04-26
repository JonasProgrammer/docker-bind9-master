#!/bin/sh

[ -z "$AUTHPREFIX" -o -z "$AUTHEMAIL" ] || ( echo "You need to set \$AUTHPREFIX and \$AUTHEMAIL (canonical root@example.com -> root.example.com)" && exit 1 )

FILE=/data/zones.conf

cat /dev/null >$FILE

IFS=,

for d in $DOMAINS; do
    zonefile=""

    IFS=.
    for part in $d; do
        if [ -z "$zonefile" ]; then
            zonefile="$part"
        else
            zonefile="${part}.${zonefile}"
        fi
    done

    zonefile="/data/db.${zonefile}"

    [ -e "$zonefile" ] || ( cat >>$zonefile <<EOF
\$ORIGIN $d.
\$TTL $TTL
@       IN  SOA $AUTHPREFIX.$d. $AUTHEMAIL. (
                  1      ; serial
                  $TTL  ; refresh
                  1800   ; retry
                  604800 ; expire
                  600 )  ; negative TTL

            NS  $AUTHPREFIX.$d.
EOF
                          )

    echo "zone \"$d\" {" >>$FILE
    echo "    type master;" >>$FILE
    echo "    file \"$zonefile\";" >>$FILE
    echo "    $ZONEOPTS" >>$FILE
    echo "};" >>$FILE

    IFS=,
done

exec $(which named) -g $@
