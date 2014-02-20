local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_DEALER))
socket.options.identity = "Client #2"
assert(socket.connect("tcp://localhost:12345"))

local len = assert(socket.send("Test message"))
if len and len > 0 then
	local poll = zmq.poll()
	
	poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
		assert(socket.recv(1))
		result = assert(socket.recvAll())

		print(result)
	end)

	poll.start()

end
socket.diconnect()
