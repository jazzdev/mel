#
# mel - IRC bot that delivers messages to offline users when they reconnect
#
irc = require 'irc'
argv = require('optimist')
  .usage('Usage: $0 [--ssl] -s <server> [-u <user>] [-p <password>] -c <channel>')
  .demand(['s','c'])
  .argv

msgs =
  'mel': ['Message delivery service, at your service, try "mel help"']

client = new irc.Client argv.s, 'mel',
  channels: [argv.c]
  autoConnect: false	# so I can add listeners before connecting
  secure: argv.ssl
  userName: argv.u
  password: argv.p
  selfSigned: true
  certExpired: true

client.addListener 'error', (error) ->
  if error.command != 'err_nosuchnick'
    console.log 'error:', error

client.addListener 'message', (nick, to, text, message) ->
  if text.match /^!?mel /
    handleCommand nick, text

handleCommand = (nick, text) ->
  word = text.split ' ', 3
  cmd = word[1]
  who = word[2]
  msg = text.match /\S+ \S+ \S+ (.*)/
  msg = msg[1] if msg
  if cmd is 'tell'
    if not who
      client.say argv.c, "tell who?"
    else if not msg
      client.say argv.c, "tell " + who + " what?"
    else
      handleMessage nick, who, msg      
  else if cmd is 'help'
    client.say argv.c, 'Available commands:'
    client.say argv.c, ' tell <user> <message> - sends <message> to <user> when they reconnect'
  else if cmd is 'quit'
    client.disconnect()
    process.exit()
  else
    client.say argv.c, "I don't know how to " + cmd

handleMessage = (from, to, msg) ->
  client.whois to, (whois) ->
    if whois and whois.channels and argv.c in whois.channels
      client.say argv.c, to + ", " + from + " says: " + msg
    else
      client.say argv.c, "okay, I'll tell " + to + " when they reconnect"
      saveMessage to, to + ", " + from + " says: " + msg

saveMessage = (nick, msg) ->
  msgs[nick] ?= []
  msgs[nick].push msg

client.addListener 'join', (channel, nick, message) ->
  console.log nick + " joined" + " " + channel
  msglist = msgs[nick]
  if argv.c.toLowerCase() is channel.toLowerCase() and msglist
    client.say argv.c, msg for msg in msglist
    msgs[nick] = []

client.connect()
