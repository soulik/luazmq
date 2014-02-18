local zmq = require 'zmq'

local context, msg = assert(zmq.context())
local socket,msg = assert(context.socket(zmq.ZMQ_REQ))

socket.options.identity = "Client #1"

local result, msg = assert(socket.connect("tcp://localhost:12345"))
local len = socket.send("Test message")
if len and len > 0 then
	print("msg sent:",len)
	repeat
		local result, msg = socket.recvAll()
		if result then
			print(#result, result)
		else
			io.write(".")
		end
	until msg ~= "Resource temporarily unavailable"
end
socket.diconnect()
