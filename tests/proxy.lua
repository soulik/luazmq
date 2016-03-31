local generator = [[
	local name = "Thread 1"

	local socket,msg = assert(context.socket(zmq.ZMQ_PUSH))

	local result, msg = assert(socket.connect("tcp://127.0.0.1:12345"))

	local poll = zmq.poll {
		{socket, zmq.ZMQ_POLLOUT, function(socket)
			socket.send(('%s'):format(os.date()))
		end},
	}

	while true do
		poll.start()
		zmq.sleep(1)
	end
	socket.close()
]]

local worker = [[
	local name = "Thread 2"

	local socket,msg = assert(context.socket(zmq.ZMQ_PULL))

	local result, msg = assert(socket.bind("tcp://127.0.0.1:12346"))

	local poll = zmq.poll {
		{socket, zmq.ZMQ_POLLIN, function(socket)
			local text = socket.recv(4096)
			print('Worker:', text)
		end},
	}

	while true do
		poll.start()
	end
	socket.close()
]]

local capture = [[
	local name = "Thread 3"

	local socket,msg = assert(context.socket(zmq.ZMQ_PAIR))

	local result, msg = assert(socket.bind("tcp://127.0.0.1:12347"))


	local poll = zmq.poll {
		{socket, zmq.ZMQ_POLLIN, function(socket)
			local text = socket.recv(4096)
			print('Capture:', text)
		end},
	}

	while true do
		poll.start()
	end
	socket.close()
]]

local controller = [[
	local name = "Thread 3"

	local socket,msg = assert(context.socket(zmq.ZMQ_PUSH))

	local result, msg = assert(socket.bind("tcp://127.0.0.1:12348"))

	local state = 0

	local poll = zmq.poll {
		{socket, zmq.ZMQ_POLLOUT, function(socket)
			if state%2 == 0 then
				print('Controller:', 'Pause!')
				socket.send('PAUSE')
			else
				print('Controller:', 'Resume!')
				socket.send('RESUME')
			end
			state = state + 1
		end},
	}

	while true do
		poll.start()
		zmq.sleep(5)
	end
	socket.close()
]]

local zmq = require 'zmq'

local context, msg = assert(zmq.context())
local socketIn,msg = assert(context.socket(zmq.ZMQ_PULL))
local result, msg = assert(socketIn.bind("tcp://127.0.0.1:12345"))

local socketOut, msg = assert(context.socket(zmq.ZMQ_PUSH))
local result, msg = assert(socketOut.connect("tcp://127.0.0.1:12346"))

local socketCapture, msg = assert(context.socket(zmq.ZMQ_PAIR))
local result, msg = assert(socketCapture.connect("tcp://127.0.0.1:12347"))

local socketControl, msg = assert(context.socket(zmq.ZMQ_PULL))
local result, msg = assert(socketControl.connect("tcp://127.0.0.1:12348"))

local threads = {
	context.thread(generator),
	context.thread(worker),
	context.thread(capture),
	context.thread(controller),
}

zmq.proxySteerable(socketIn, socketOut, socketCapture, socketControl)

for _, thread in ipairs(threads) do
	thread.join()
end

socket.close()
