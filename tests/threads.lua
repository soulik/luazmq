local zmq = require 'zmq'

local req = [[
	local zmq = require 'zmq'
	local context, msg = assert(zmq.context(assert(select(1, ...))))
	local name = "Thread 1"

	local socket,msg = assert(context.socket(zmq.ZMQ_REQ))
	socket.options.identity = name

	local result, msg = assert(socket.connect("tcp://127.0.0.1:12345"))

	local poll = zmq.poll()

	poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
		local result = socket.recvAll()
		if result then
			print(string.format("1 Recieved data: %q from: %s", result, name))
		end
	end)

	socket.send(":)")

	while true do
		poll.start()
	end
	socket.close()
]]

--local zmq = require 'zmq'

local context, msg = assert(zmq.context())
local socket,msg = assert(context.socket(zmq.ZMQ_ROUTER))
socket.options.identity = "Server"
local result, msg = assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll()

poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
	local name = assert(socket.recv(256))
	--print(string.format("0 Name: %q %s", name, zmq.tohex(name)))
	if socket.more then
		local d = assert(socket.recv(1))
		--print(string.format("0 Waiting for data...: %q %s", d, zmq.tohex(d)))
	end
	local result = socket.recvAll()
	if result then
		print(string.format("0 Recieved data: %q from: %q", result, name))

		local data = "Hello: "..result
		--print(string.format("0 Sending reply to: %q", name))
		socket.sendID(name)
		socket.send(data)
	end
end)

print("0 Waiting for connections")
local t1 = context.thread(req)
while true do
	poll.start()
end
t1.join()
socket.close()
