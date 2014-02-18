local zmq = require 'zmq'

local context, msg = assert(zmq.context())
local socket,msg = assert(context.socket(zmq.ZMQ_REP))
local result, msg = assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll()
	
poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
	local result, msg = socket.recvAll()
	if result then
		local data = "Hello: "..result
		socket.send(data)
		print(result, data, 'from: ', string.format("%q",socket.options.identity))
	end
end)

while true do
	poll.start()
end
socket.close()
