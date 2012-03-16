#!/bin/bash

user=`cat username`
gateway=`/sbin/ip route | awk '/default/{ print $3 }'`

ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=publickey -o BatchMode=yes -NL 8080:proxy:3128 $user@$gateway &>/dev/null &

rm /etc/apt/apt.conf.d/proxy*
echo 'Acquire::http::Proxy "http://127.0.0.1:8080";' > /etc/apt/apt.conf.d/proxy