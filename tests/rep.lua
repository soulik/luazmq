local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_REP))
assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll {
	{socket, zmq.ZMQ_POLLIN, function(socket)
		local result = assert(socket.recvAll())
		local identity = socket.options.identity
		local data = "Hello: "..identity..". This is a reply to: "..result
		print('Received: ', result, 'from: ', identity)
		assert(socket.send(data))
	end},
}

while true do
	poll.start(500)
end
socket.close()
