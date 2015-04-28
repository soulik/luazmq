local zmq = require 'zmq'
require 'utils/pstring'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_STREAM))
socket.options.stream_notify = true
socket.options.ipv6 = true
assert(socket.connect("tcp://www.google.com:80"))

local poll = zmq.poll()

local once = false

poll.add(socket, zmq.ZMQ_POLLIN, function(socket)
	local identity = socket.options.identity
	local id = assert(socket.recv())
	local data = assert(socket.recv())
	print("%q\n%q" % {zmq.tohex(id), data})

	if not once then
		assert(socket.send(identity, zmq.ZMQ_SNDMORE))
		assert(socket.send([[GET / HTTP/1.1

]], zmq.ZMQ_SNDMORE))
		once = true
	end
end)

while true do
	poll.start()
end
socket.disconnect()
