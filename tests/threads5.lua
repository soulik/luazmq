local zmq = require 'zmq'

local context, msg = assert(zmq.context())

-- job socket
local socket,msg = assert(context.socket(zmq.ZMQ_DEALER))
assert(socket.bind("inproc://main"))

-- notify socket publisher
local nsocket,msg = assert(context.socket(zmq.ZMQ_PUB))
assert(nsocket.bind("inproc://notify"))

local worker = function(_ctx, ...)
	local zmq = require 'zmq'
	local workerId = select(1, ...)
	local context, msg = assert(zmq.context(_ctx))
	
	-- job socket
	local socket,msg = assert(context.socket(zmq.ZMQ_DEALER))
	assert(socket.connect("inproc://main"))

	-- notify socket subscriber
	local nsocket,msg = assert(context.socket(zmq.ZMQ_SUB))
	assert(nsocket.connect("inproc://notify"))
	nsocket.options.subscribe = 'worker'

	local running = true

	local poll = zmq.poll {
		{socket, zmq.ZMQ_POLLIN, function(socket)
			local arg = socket.recvMultipart()

			local job, id = arg[1], arg[2]

			-- a job command
			if job and id then
				local jobFn = loadstring(job)

				local r,m = pcall(jobFn, id)
				if r then
					socket.sendMultipart {tostring(workerId), tostring(m)}
				else
					socket.send(("Worker #%d Error: %s"):format(tonumber(workerId), tostring(m)))
				end
			else
				socket.send(("Worker #%d Unknown command"):format(tonumber(workerId)))
			end
		end},
		{nsocket, zmq.ZMQ_POLLIN, function(socket)
			local arg = socket.recvMultipart()
			local command = arg[2]

			-- a thread close command
			if command == 'close' then
				running = false
			end
		end},
	}

	while running do
		poll.start(100)
	end
	socket.close()
end

do
	local N = 5
	local Njobs = 100
	local threads = {}
	local results = {}

	-- prepare all worker threads
    for i=1,N do
    	local thread = assert(context.thread2(worker, i))
		table.insert(threads, thread)
	end

	local poll = zmq.poll {
		{socket, zmq.ZMQ_POLLIN, function(socket)
			-- store worker result
			local reply = socket.recvMultipart()
			if reply and (#reply >=2 ) then
				local tmp = ("%s - from worker ID: %d"):format(reply[2], tonumber(reply[1]))
				table.insert(results, tmp)
			end
		end},
	}

	-- generic job function sent as a byte-code dump
    local jobFn = string.dump(
    	function(i)
    		return ("Job #%d"):format(tonumber(i))
    	end
    )

	-- generic job function sent as a source string
   	local jobSrc = [==[
   		local i = select(1, ...)
   		return ("Job #%d"):format(tonumber(i))
   	]==]

	print('Ready to process')

	-- send jobs to all workers
    for i=1,Njobs do
    	if i % 2 == 0 then
	    	socket.sendMultipart {jobFn, tostring(i)}
    	else
	    	socket.sendMultipart {jobSrc, tostring(i)}
    	end
    end

	print('Waiting for results')
    -- wait for sufficient amount of results
	while (#results < Njobs) do
		poll.start()
	end

	for _, result in ipairs(results) do
		print(result)
	end

	-- send 'close' command to all workers
   	nsocket.sendMultipart {'worker', 'close'}
end

print('Exiting')
