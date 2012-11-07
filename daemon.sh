#!/bin/bash

export PATH=$PATH:/usr/local/bin/

DIR=`dirname $0`
COFFEE=/usr/local/bin/coffee
HOST=irc.docusignhq.com
LOGIN=`perl -MNet::Netrc -e "print Net::Netrc->lookup('$HOST')->login"`
PASS=`perl -MNet::Netrc -e "print Net::Netrc->lookup('$HOST')->password"`

$COFFEE $DIR/mel.coffee \
  -s $HOST --ssl \
  -u $LOGIN -p $PASS >> $DIR/daemon.log 2>&1
