local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_REQ))
socket.options.identity = "Client #1"
assert(socket.connect("tcp://localhost:12345"))

local len = assert(socket.send("Test message"))
if len and len > 0 then
	local poll = zmq.poll()
	
	poll.add(socket, zmq.ZMQ_POLLIN, function(s)
		local result = assert(socket.recvAll())
		print(result)
	end)

	poll.start()

end
socket.diconnect()
