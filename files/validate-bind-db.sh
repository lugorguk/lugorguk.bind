#! /bin/bash
if [ ! -e "$1" ]
then
  echo "Missing source file."
  exit 2
fi
if [ ! -e "$2" ]
then
  echo "Missing destination file. Copying $1 to $2."
  mv "$1" "$2"
  exit 1
fi
source=$(grep -vE "\s+[0-9]{10}\s+" "$1" | md5sum - | cut -d\  -f1)
destination=$(grep -vE "\s+[0-9]{10}\s+" "$2" | md5sum - | cut -d\  -f1)
if [ "$source" == "$destination" ]
then
  echo "No differences."
  rm "$1"
  exit 0
else
  echo "Differences. Replacing $1 ($source) over $2 ($destination)."
  grep -vE "\s+[0-9]{10}\s+" "$1" > /tmp/bind_diff_src
  grep -vE "\s+[0-9]{10}\s+" "$2" > /tmp/bind_diff_dst
  diff /tmp/bind_diff_src /tmp/bind_diff_dst
  rm /tmp/bind_diff_src /tmp/bind_diff_dst
  if [ -n "$3" ]
  then
    cp "$2" "$2~"
    /usr/sbin/named-checkconf -z "/etc/bind/named.conf" 2>&1 > "/tmp/named-checkconf.out"
    if [ $? -gt 0 ]
    then
      cat "/tmp/named-checkconf.out"
      rm "$1" "$2~" "/tmp/named-checkconf.out"
      exit 3
    fi
  fi
  mv "$1" "$2"
  rm -f "/tmp/named-checkconf.out"
  exit 1
fi
