local zmq = require 'zmq'

local context, msg = assert(zmq.context())
local socket,msg = assert(context.socket(zmq.ZMQ_ROUTER))
local result, msg = assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll()

poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
	local name = assert(socket.recv(256))
	print(string.format("Name: %q %s", name, zmq.tohex(name)))
	if socket.more then
		local d = assert(socket.recv(1))
		print(string.format("Waiting for data...: %q %s", d, zmq.tohex(d)))
	end
	local result = socket.recvAll()
	if result then
		print(string.format("Recieved data: %q from: %q", result, name))

		local data = "Hello: "..result
		print(string.format("Sending reply to: %q", name))
		socket.sendID(name)
		socket.send(data)
	end
end)

while true do
	poll.start()
end
socket.close()
