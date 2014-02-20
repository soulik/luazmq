local zmq = require 'zmq'

local context = assert(zmq.context())
local socket = assert(context.socket(zmq.ZMQ_REQ))

socket.options.identity = "Client #1"

assert(socket.connect("tcp://localhost:12345"))
local len = assert(socket.send("Test message"))
local result = assert(socket.recvAll())

print('Returned answer: ', result)

socket.diconnect()
