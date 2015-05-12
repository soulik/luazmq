local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_ROUTER))
assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll {
	{socket, zmq.ZMQ_POLLIN, function(socket)
		local name = assert(socket.recv(256))
		print(string.format("Name: %q %s", name, zmq.tohex(name)))

		local result = assert(socket.recvAll())
		print(string.format("Recieved data: %q from: %q", result, name))

		local data = "Hello: "..result
		print(string.format("Sending reply to: %q", name))
	
		assert(socket.sendID(name))
		assert(socket.send(data))
	end},
}

while true do
	poll.start()
end

socket.close()
