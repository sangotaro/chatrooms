socketio = require 'socket.io'
io = null
guestNumber = 1
nickNames = {}
namesUsed = []
currentRoom = {}

assignGuestName = (socket, guestNumber, nickNames, namesUsed) ->
  name = 'Guest' + guestNumber
  nickNames[socket.id] = name

  socket.emit 'nameResult', { success: true, name: name }

  namesUsed.push name

  guestNumber + 1

findClientsSocketByRoomId = (roomId) ->
  res = []
  room = io.sockets.adapter.rooms[roomId]
  if room
    for id in room
      res.push io.sockets.adapter.nsp.connected[id]

  return res

joinRoom = (socket, room) ->
  socket.join room

  currentRoom[socket.id] = room

  socket.emit 'joinResult', room: room

  socket.broadcast
    .to room
    .emit 'message', text: "#{nickNames[socket.id]} has joined #{room}."

  #usersInRoom = io.sockets.clients room
  usersInRoom = findClientsSocketByRoomId(room)

  if usersInRoom.length > 1
    usersInRoomSummary = "Users currently in #{room}: "

    for index of usersInRoom
      userSocketId = usersInRoom[index].id
      if userSocketId != socket.id
        if index > 0
          usersInRoomSummary += ','
        usersInRoomSummary += nickNames[userSocketId]

  usersInRoomSummary += '.'
  socket.emit 'message', text: usersInRoomSummary


handleNameChangeAttempts = (socket, nickNames, namesUsed) ->
  socket.on 'nameAttempt', (name) =>
    if name.indexOf 'Guest' == 0
      socket.emit 'nameResult',
        { success: false, message: 'Names cannot begin with "Guest".' }
    else
      if namesUsed.indexOf name == 1
        previousName = nickNames[socket.id]
        previousNameIndex = nameUsed.indexOf previousName
        namesUsed.push name
        nickNames[socket.id] = name
        delete namesUsed[previousNameIndex]

        socket.emit 'nameResult', { success: true, name: name }
        socket.broadcast
          .to currentRoom[socket.id]
          .emit 'message', { text: "#{previousName} is now know as #{name}" }
      else
        socket.emit 'nameResult', { success: false, name: 'That name is already in use' }


handleMessageBroadcasting = (socket) ->
  socket.on 'message', (message) =>
    socket.broadcast
      .to message.room
      .emit 'message', { text: nickNames[socket.id] + ': ' + message.text }

handleRoomJoining = (socket) ->
  socket.on 'join', (room) =>
    socket.leave currentRoom[socket.id]
    joinRoom socket, room.newRoom

handleClientDisconnection = (socket) ->
  socket.on 'disconnect', () =>
    nameIndex = namesUsed.indexOf nickNames[socket.id]
    delete namesUsed[nameIndex]
    delete nickNames[socket.id]

exports.listen = (server) ->
  io = socketio.listen server

  io.set 'log level', 1

  io.sockets.on 'connection', (socket) =>

    # ゲスト名の割り当て
    guestNumber = assignGuestName socket, guestNumber, nickNames, namesUsed

    # ユーザをLobbyに入れる
    joinRoom socket, 'Lobby'

    # メッセージを処理
    handleMessageBroadcasting socket

    # 名前変更を処理
    handleNameChangeAttempts socket, nickNames, namesUsed

    # ロームの作成/変更の要求を処理
    handleRoomJoining socket

    # 使用されているルームリストを提供
    socket.on 'rooms', () =>
      socket.emit 'rooms', io.sockets.rooms

    # 接続を断ったときのクリーンアップ
    handleClientDisconnection socket, nickNames, namesUsed
