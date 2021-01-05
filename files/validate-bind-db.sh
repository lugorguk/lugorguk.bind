#! /bin/bash
INFILE="$1"
OUTFILE="$2"
CHECKNAMEDCONF="$3"

if [ ! -e "$INFILE" ]
then
  echo "Missing source file."
  exit 2
fi
if [ ! -e "$OUTFILE" ]
then
  echo "Missing destination file. Copying $INFILE to $OUTFILE."
  mv "$INFILE" "$OUTFILE"
  exit 1
fi
source=$(grep -vE '\s+[0-9]{10}\s+' "$INFILE" | md5sum - | cut -d\  -f1)
destination=$(grep -vE '\s+[0-9]{10}\s+' "$OUTFILE" | md5sum - | cut -d\  -f1)
if [ "$source" == "$destination" ]
then
  echo "No differences."
  rm "$INFILE"
  exit 0
else
  echo "Differences. Replacing $INFILE ($source) over $OUTFILE ($destination)."
  grep -vE '\s+[0-9]{10}\s+' "$INFILE" > /tmp/bind_diff_src
  grep -vE '\s+[0-9]{10}\s+' "$OUTFILE" > /tmp/bind_diff_dst
  diff /tmp/bind_diff_src /tmp/bind_diff_dst
  rm /tmp/bind_diff_src /tmp/bind_diff_dst
  if [ -n "$CHECKNAMEDCONF" ]
  then
    cp "$OUTFILE" "$OUTFILE~"
    if /usr/sbin/named-checkconf -z "/etc/bind/named.conf" >"/tmp/named-checkconf.out" 2>&1
    then
      cat "/tmp/named-checkconf.out"
      rm "$INFILE" "$OUTFILE~" "/tmp/named-checkconf.out"
      exit 3
    fi
    rm -f "/tmp/named-checkconf.out"
  fi
  mv "$INFILE" "$OUTFILE"
  exit 1
fi
