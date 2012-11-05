#
# mel - IRC bot that delivers messages to offline users when they reconnect
#
irc = require 'irc'
argv = require('commander')
  .option('-s, --server <hostname>', 'IRC server')
  .option('-c, --channel <name>,', 'IRC channel')
  .option('--ssl', 'Use SSL')
  .option('-u, --user <login>')
  .option('-p, --pass [password]')
  .parse(process.argv)

msgs =
  'mel': ['Message delivery service, at your service, try "mel help"']

main = () ->
  if argv.pass is true
    argv.password 'Password: ', (pass) ->
      argv.pass = pass
      connect()
  else
    connect()

connect = () ->
  client = new irc.Client argv.server, 'mel',
    channels: [argv.channel]
    autoConnect: false	# so I can add listeners before connecting
    secure: argv.ssl
    userName: argv.user
    password: argv.pass
    selfSigned: true
    certExpired: true

  client.addListener 'error', (error) ->
    if error.command != 'err_nosuchnick'
      console.log 'error:', error

  client.addListener 'message', (nick, to, text, message) ->
    if text.match /^!?mel /
      handleCommand client, nick, text

  client.addListener 'join', (channel, nick, message) ->
    console.log nick + " joined" + " " + channel
    msglist = msgs[nick]
    if argv.channel.toLowerCase() is channel.toLowerCase() and msglist
      client.say argv.channel, msg for msg in msglist
      msgs[nick] = []

  client.connect()

handleCommand = (client, nick, text) ->
  word = text.split ' ', 3
  cmd = word[1]
  who = word[2]
  msg = text.match /\S+ \S+ \S+ (.*)/
  msg = msg[1] if msg
  if cmd is 'tell'
    if not who
      client.say argv.channel, "tell who?"
    else if not msg
      client.say argv.channel, "tell " + who + " what?"
    else
      handleMessage client, nick, who, msg      
  else if cmd is 'help'
    client.say argv.channel, 'Available commands:'
    client.say argv.channel, ' tell <user> <message> - sends <message> to <user> when they reconnect'
  else if cmd is 'quit'
    client.disconnect()
    process.exit()
  else
    client.say argv.channel, "I don't know how to " + cmd

handleMessage = (client, from, to, msg) ->
  client.whois to, (whois) ->
    if whois and whois.channels and argv.channel in whois.channels
      client.say argv.channel, to + ", " + from + " says: " + msg
    else
      client.say argv.channel, "okay, I'll tell " + to + " when they reconnect"
      msgs[to] ?= []
      msgs[to].push to + ", " + from + " says: " + msg

main()
