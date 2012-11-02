#
# mel - IRC bot that delivers messages to offline users when they reconnect
#
irc = require 'irc'
chan = '#Foo'

client = new irc.Client 'localhost', 'mel',
  channels: [chan]
  autoConnect: false

client.addListener 'error', (message) ->
  console.log 'error:', message

client.addListener 'registered', (m) ->
  console.log 'mel: joined chat room'
  client.say chan, 'Send me your tired, your poor...'
  
client.addListener 'message', (nick, to, text, message) ->
  console.log 'heard', nick, to, text
  if text.match /^!?mel /
    handle nick, text

handle = (nick, text) ->
  console.log 'parsing', text
  word = text.split(' ')
  cmd = word[1]
  who = word[2]
  msg = text.match(/\S+ \S+ \S+ (.*)/)
  msg = msg[1] if msg
  if cmd is 'tell'
    console.log 'telling...'
    if not who
      client.say chan, "tell who?"
    else if not msg
      client.say chan, "tell " + who + " what?"
    else
      client.say chan, "okay, I'll tell " + who + " when they reconnect"
      console.log 'telling', who
  else if cmd is 'quit'
    client.disconnect()
    process.exit()
  else
    client.say chan, "I don't know how to " + word[1]

client.connect()



