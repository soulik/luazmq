local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_PUB))
assert(socket.bind("tcp://*:12345"))

local poll = zmq.poll()

poll.add(socket, zmq.ZMQ_POLLOUT, function(socket)
	assert(socket.sendMultipart({'demo', 'Hello everyone!'}))
end)

local lastTime = os.clock()
while true do
	local newTime = os.clock()
	if (newTime-lastTime) >= 1 then
		lastTime = newTime
		poll.start()
	end
end
socket.close()
