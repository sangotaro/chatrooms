divEscapedContentElement = (message) ->
  $('<div></div>').text(message)

divSystemContentElement = (message) ->
  $('<div></div>').html('<i>' + message + '</i>')

processUserInput = (chatApp, socket) ->
  message = $('#send-message').val()

  if message.charAt(0) == '/'
    systemMessage = chatApp.processCommand(message)
    if systemMessage
      $('#message').append(divSystemContentElement systemMessage)

  else
    chatApp.sendMessage $('#message').text(), message

    $('#message').append(divEscapedContentElement message)
    $('#message').scrollTop($('#message').prop('scrollHeight'))

  $('#send-message').val('')


socket = io.connect()

$ ->
  chatApp = new Chat socket

  socket.on 'nameResult', (result) =>
    if result.success
      message = 'You are now known as ' + result.name + '.'
    else
      message = result.message

    $('#message').append(divSystemContentElement message)

  socket.on 'joinResult', (result) =>
    $('#room').text result.room
    $('#message').append(divSystemContentElement 'Room changed.')

  socket.on 'message', (message) =>
    newElement = $('<div></div>').text message.text
    $('#message').append newElement

  socket.on 'rooms', (rooms) =>
    $('#room-list').empty()
    for room of rooms
      room = room.substring 1, room.length
      if room != ''
        $('#room-list').append divEscapedContentElement room

    $('#room-list div').click () =>
      chatApp.processCommand '/join ' + $(this).text()
      $('#send-message').focus()

  setInterval () ->
    socket.emit 'rooms'
  , 1000

  $('#send-message').focus()

  $('#send-form').submit () =>
    processUserInput chatApp, socket
    return false