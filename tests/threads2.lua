local zmq = require 'zmq'

local req = [[
	local zmq = require 'zmq'
	local context, msg = assert(zmq.context(assert(select(1, ...))))

	local socket,msg = assert(context.socket(zmq.ZMQ_REQ))

	local result, msg = assert(socket.connect("inproc://test1"))
	--print(name, "connected")

	local poll = zmq.poll()

	poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
		local result = socket.recvAll()
		if result then
			print(name, string.format("Recieved data: %q", result))
		end
	end)

	socket.send("Lorem ipsum dolor sit amet")

	while true do
		poll.start()
	end
	socket.close()
]]

--local zmq = require 'zmq'

local context, msg = assert(zmq.context())
local socket,msg = assert(context.socket(zmq.ZMQ_REP))
socket.options.identity = "Server"
local result, msg = assert(socket.bind("inproc://test1"))

local poll = zmq.poll()

poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
	local result = socket.recvAll()
	if result then
		print(string.format("0 Recieved data: %q", result))
		local data = "Hello: "..result
		socket.send(data)
	end
end)

print("0 Waiting for connections")
local threads = {}
for i=1,10 do
	local code = string.format([[
local name = %d 	
	]], i)..req
	threads[i] = context.thread(code)
end

while true do
	poll.start()
end

for _, thread in ipairs(threads) do
	thread.join()
end

socket.close()
