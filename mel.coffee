#
# mel - IRC bot that delivers messages to offline users when they reconnect
#
irc = require 'irc'

irchost = 'localhost'
chan = '#Foo'
msgs = {}

client = new irc.Client irchost, 'mel',
  channels: [chan]
  autoConnect: false

client.addListener 'error', (error) ->
  if error.command != 'err_nosuchnick'
    console.log 'error:', error

client.addListener 'registered', (m) ->
  console.log 'mel: joined chat room'
  client.say chan, 'Message delivery service, at your service, try "mel help"'
  
client.addListener 'message', (nick, to, text, message) ->
  console.log 'heard', nick, to, text
  if text.match /^!?mel /
    handleCommand nick, text

handleCommand = (nick, text) ->
  console.log 'parsing', text
  word = text.split ' ', 3
  cmd = word[1]
  who = word[2]
  msg = text.match /\S+ \S+ \S+ (.*)/
  msg = msg[1] if msg
  if cmd is 'tell'
    if not who
      client.say chan, "tell who?"
    else if not msg
      client.say chan, "tell " + who + " what?"
    else
      handleMessage nick, who, msg      
  else if cmd is 'help'
    client.say chan, 'Available commands:'
    client.say chan, ' tell <user> <message> - sends <message> to <user> when they reconnect'
  else if cmd is 'quit'
    client.disconnect()
    process.exit()
  else
    client.say chan, "I don't know how to " + cmd

handleMessage = (from, to, msg) ->
  client.whois to, (whois) ->
    console.log 'whois', whois
    if whois and whois.channels and chan in whois.channels
      client.say chan, to + ", " + from + " says: " + msg
    else
      client.say chan, "okay, I'll tell " + to + " when they reconnect"
      saveMessage to, from + " says: " + msg

saveMessage = (nick, msg) ->
  if not msgs[nick]
    msgs[nick] = []
  msgs[nick].push msg

client.addListener 'join', (channel, nick, message) ->
  console.log nick + " joined" + " " + channel
  msglist = msgs[nick]
  if chan.toLowerCase() is channel.toLowerCase() and msglist
    client.say chan, msg for msg in msglist
    msgs[nick] = []

client.connect()
