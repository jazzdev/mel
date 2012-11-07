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

msgs = {}

main = () ->
  if argv.pass is true
    argv.password 'Password: ', (pass) ->
      argv.pass = pass
      connect()
  else
    connect()

addMessage = (nick, channel, msg) ->
  to = nick + channel.toLowerCase()
  msgs[to] ?= []
  msgs[to].push msg

getMessages = (nick, channel) ->
  to = nick + channel.toLowerCase()
  msglist = msgs[to]
  msgs[to] = []
  return msglist

connect = () ->
  client = new irc.Client argv.server, 'mel',
    autoConnect: false	# so I can add listeners before connecting
    secure: argv.ssl
    userName: argv.user
    password: argv.pass
    selfSigned: true
    certExpired: true

  client.addListener 'error', (error) ->
    console.log 'error:', error

  client.addListener 'registered', (message) ->
    client.channellist = [] # initialize this in case server doesn't send list start
    client.list()

  client.addListener 'channellist', (channel_list) ->
    for channel in channel_list when channel.name isnt '&SERVER'
      addMessage 'mel', channel.name, 'Message delivery service, at your service, try "mel help"'
      client.join channel.name

  client.addListener 'message', (nick, channel, text) ->
    if text.match /^!?mel /
      handleCommand client, nick, channel, text

  client.addListener 'join', (channel, nick, message) ->
    console.log nick + " joined" + " " + channel
    msglist = getMessages nick, channel
    if msglist
      client.say channel, msg for msg in msglist

  client.connect()

handleCommand = (client, nick, channel, text) ->
  word = text.split ' ', 3
  cmd = word[1]
  who = word[2]
  msg = text.match /\S+ \S+ \S+ (.*)/
  msg = msg[1] if msg
  if cmd is 'tell'
    if not who
      client.say channel, "tell who?"
    else if not msg
      client.say channel, "tell " + who + " what?"
    else
      handleMessage client, nick, channel, who, msg
  else if cmd is 'help'
    client.say channel, 'Available commands:'
    client.say channel, ' tell <user> <message> - sends <message> to <user> when they reconnect'
  else if cmd is 'quit'
    client.disconnect()
    process.exit()
  else
    client.say channel, "I don't know how to " + cmd

handleMessage = (client, from, channel, to, msg) ->
  client.whois to, (whois) ->
    if whois and whois.channels and channel in whois.channels
      client.say channel, to + ", " + from + " says: " + msg
    else
      client.say channel, "okay, I'll tell " + to + " when they reconnect to " + channel
      addMessage to, channel, to + ", " + from + " says: " + msg

main()
