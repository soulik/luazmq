local req = [[
	local name = "Thread 1"

	local socket,msg = assert(context.socket(zmq.ZMQ_REQ))
	socket.options.identity = name

	local result, msg = assert(socket.connect("tcp://127.0.0.1:12345"))

	local poll = zmq.poll {
		{socket, zmq.ZMQ_POLLIN, function(socket)
			local result = assert(socket.recvAll())
			if result then
				print(string.format("1 Recieved data: %q", result))
			end
		end},
	}

	socket.send(":)")

	while true do
		poll.start()
	end
	socket.close()
]]

local zmq = require 'zmq'

local context, msg = assert(zmq.context())
local socket,msg = assert(context.socket(zmq.ZMQ_ROUTER))
local result, msg = assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll {
	{socket, zmq.ZMQ_POLLIN, function(socket)
		local name, _, result = unpack(assert(socket.recvMultipart()))
		print(string.format("0 Recieved data: %q from: %q", result, name))
		local data = "Hello: "..tostring(result)
		socket.sendMultipart({name, '', data})
	end},
}

print("0 Waiting for connections")
local t1 = context.thread(req)
while true do
	poll.start()
end
t1.join()
socket.close()
