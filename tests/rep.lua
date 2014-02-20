local zmq = require 'zmq'

local context, msg = assert(zmq.context())
local socket,msg = assert(context.socket(zmq.ZMQ_REP))
local result, msg = assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll()
	
poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
	local result = assert(socket.recvAll())
	local data = "Hello: "..socket.options.identity..". This is a reply to: "..result
	socket.send(data)
	print('Received: ', result, 'from: ', socket.options.identity)
end)

while true do
	poll.start()
end
socket.close()
