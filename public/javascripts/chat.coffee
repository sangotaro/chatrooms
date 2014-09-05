class @Chat
  constructor: (@socket) ->

  sendMessage: (room, text) =>
    message =
      room: room
      text: text

    @socket.emit 'message', massage

  changeRoom: (room) =>
    @socket.emit 'join', newRoom: room

  processCommand: (command) =>
    words = command.split ' '
    command = words[0]
      .substring 1, words[0].length
      .toLowerCase()
    message = false

    switch command
      when 'join'
        words.shift()
        room = words.join ' '
        @changeRoom room

      when 'nick'
        words.shift()
        name = words.join ' '
        @socket.emit 'nameAttempt', name

      else
        message = 'Unrecognized command.'

    return message