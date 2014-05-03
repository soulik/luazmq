local zmq = require 'luazmq'
local M = {}

local constants = {
	ZMQ_PAIR = 					0,
    ZMQ_PUB =					1,
    ZMQ_SUB =					2,
    ZMQ_REQ =					3,
    ZMQ_REP =					4,
    ZMQ_DEALER =				5,
    ZMQ_ROUTER =				6,
    ZMQ_PULL =					7,
    ZMQ_PUSH =					8,
    ZMQ_XPUB =					9,
    ZMQ_XSUB =					10,
    ZMQ_STREAM =				11,

    ZMQ_XREQ = 					5, --ZMQ_DEALER
    ZMQ_XREP = 					6, --ZMQ_ROUTER
                       	
    ZMQ_AFFINITY =				4,
    ZMQ_IDENTITY =				5,
    ZMQ_SUBSCRIBE =				6,
    ZMQ_UNSUBSCRIBE =			7,
    ZMQ_RATE =					8,
    ZMQ_RECOVERY_IVL =			9,
    ZMQ_SNDBUF =				11,
    ZMQ_RCVBUF =				12,
    ZMQ_RCVMORE =				13,
    ZMQ_FD =					14,
    ZMQ_EVENTS =				15,
    ZMQ_TYPE =					16,
    ZMQ_LINGER =				17,
    ZMQ_RECONNECT_IVL =			18,
    ZMQ_BACKLOG =				19,
    ZMQ_RECONNECT_IVL_MAX =		21,
    ZMQ_MAXMSGSIZE =			22,
    ZMQ_SNDHWM =				23,
    ZMQ_RCVHWM =				24,
    ZMQ_MULTICAST_HOPS =		25,
    ZMQ_RCVTIMEO =				27,
    ZMQ_SNDTIMEO =				28,
    ZMQ_LAST_ENDPOINT =			32,
    ZMQ_ROUTER_MANDATORY =		33,
    ZMQ_TCP_KEEPALIVE =			34,
    ZMQ_TCP_KEEPALIVE_CNT =		35,
    ZMQ_TCP_KEEPALIVE_IDLE =	36,
    ZMQ_TCP_KEEPALIVE_INTVL =	37,
    ZMQ_TCP_ACCEPT_FILTER =		38,
    ZMQ_IMMEDIATE =				39,
    ZMQ_XPUB_VERBOSE =			40,
    ZMQ_ROUTER_RAW =			41,
    ZMQ_IPV6 =					42,
    ZMQ_MECHANISM =				43,
    ZMQ_PLAIN_SERVER =			44,
    ZMQ_PLAIN_USERNAME =		45,
    ZMQ_PLAIN_PASSWORD =		46,
    ZMQ_CURVE_SERVER =			47,
    ZMQ_CURVE_PUBLICKEY =		48,
    ZMQ_CURVE_SECRETKEY =		49,
    ZMQ_CURVE_SERVERKEY =		50,
    ZMQ_PROBE_ROUTER =			51,
    ZMQ_REQ_CORRELATE =			52,
    ZMQ_REQ_RELAXED =			53,
    ZMQ_CONFLATE =				54,
    ZMQ_ZAP_DOMAIN =			55,

	ZMQ_MORE =					1,

	ZMQ_DONTWAIT =				1,
	ZMQ_SNDMORE =				2,

	ZMQ_NULL =					0,
	ZMQ_PLAIN =					1,
	ZMQ_CURVE =					2,

	ZMQ_EVENT_CONNECTED =		1,
	ZMQ_EVENT_CONNECT_DELAYED =	2,
	ZMQ_EVENT_CONNECT_RETRIED =	4,
	ZMQ_EVENT_LISTENING =		8,
	ZMQ_EVENT_BIND_FAILED =		16,
	ZMQ_EVENT_ACCEPTED =		32,
	ZMQ_EVENT_ACCEPT_FAILED =	64,
	ZMQ_EVENT_CLOSED =			128,
	ZMQ_EVENT_CLOSE_FAILED =	256,
	ZMQ_EVENT_DISCONNECTED =	512,
	ZMQ_EVENT_MONITOR_STOPPED =	1024,
	ZMQ_EVENT_ALL =				0x7FF,

	ZMQ_POLLIN =				1,
	ZMQ_POLLOUT =				2,
	ZMQ_POLLERR =				4,
}

local socket_option_names = {
    ['AFFINITY'] = 				constants.ZMQ_AFFINITY,
    ['IDENTITY'] = 				constants.ZMQ_IDENTITY,
    ['SUBSCRIBE'] = 			constants.ZMQ_SUBSCRIBE,
    ['UNSUBSCRIBE'] = 			constants.ZMQ_UNSUBSCRIBE,
    ['RATE'] = 					constants.ZMQ_RATE,
    ['RECOVERY_IVL'] = 			constants.ZMQ_RECOVERY_IVL,
    ['SNDBUF'] = 				constants.ZMQ_SNDBUF,
    ['RCVBUF'] = 				constants.ZMQ_RCVBUF,
    ['RCVMORE'] = 				constants.ZMQ_RCVMORE,
    ['FD'] = 					constants.ZMQ_FD,
    ['EVENTS'] = 				constants.ZMQ_EVENTS,
    ['TYPE'] = 					constants.ZMQ_TYPE,
    ['LINGER'] = 				constants.ZMQ_LINGER,
    ['RECONNECT_IVL'] = 		constants.ZMQ_RECONNECT_IVL,
    ['BACKLOG'] = 				constants.ZMQ_BACKLOG,
    ['RECONNECT_IVL_MAX'] = 	constants.ZMQ_RECONNECT_IVL_MAX,
    ['MAXMSGSIZE'] = 			constants.ZMQ_MAXMSGSIZE,
    ['SNDHWM'] = 				constants.ZMQ_SNDHWM,
    ['RCVHWM'] = 				constants.ZMQ_RCVHWM,
    ['MULTICAST_HOPS'] = 		constants.ZMQ_MULTICAST_HOPS,
    ['RCVTIMEO'] = 				constants.ZMQ_RCVTIMEO,
    ['SNDTIMEO'] = 				constants.ZMQ_SNDTIMEO,
    ['LAST_ENDPOINT'] = 		constants.ZMQ_LAST_ENDPOINT,
    ['ROUTER_MANDATORY'] = 		constants.ZMQ_ROUTER_MANDATORY,
    ['TCP_KEEPALIVE'] = 		constants.ZMQ_TCP_KEEPALIVE,
    ['TCP_KEEPALIVE_CNT'] = 	constants.ZMQ_TCP_KEEPALIVE_CNT,
    ['TCP_KEEPALIVE_IDLE'] = 	constants.ZMQ_TCP_KEEPALIVE_IDLE,
    ['TCP_KEEPALIVE_INTVL'] = 	constants.ZMQ_TCP_KEEPALIVE_INTVL,
    ['TCP_ACCEPT_FILTER'] = 	constants.ZMQ_TCP_ACCEPT_FILTER,
    ['IMMEDIATE'] = 			constants.ZMQ_IMMEDIATE,
    ['XPUB_VERBOSE'] = 			constants.ZMQ_XPUB_VERBOSE,
    ['ROUTER_RAW'] = 			constants.ZMQ_ROUTER_RAW,
    ['IPV6'] = 					constants.ZMQ_IPV6,
    ['MECHANISM'] = 			constants.ZMQ_MECHANISM,
    ['PLAIN_SERVER'] = 			constants.ZMQ_PLAIN_SERVER,
    ['PLAIN_USERNAME'] = 		constants.ZMQ_PLAIN_USERNAME,
    ['PLAIN_PASSWORD'] = 		constants.ZMQ_PLAIN_PASSWORD,
    ['CURVE_SERVER'] = 			constants.ZMQ_CURVE_SERVER,
    ['CURVE_PUBLICKEY'] = 		constants.ZMQ_CURVE_PUBLICKEY,
    ['CURVE_SECRETKEY'] = 		constants.ZMQ_CURVE_SECRETKEY,
    ['CURVE_SERVERKEY'] = 		constants.ZMQ_CURVE_SERVERKEY,
    ['PROBE_ROUTER'] = 			constants.ZMQ_PROBE_ROUTER,
    ['REQ_CORRELATE'] = 		constants.ZMQ_REQ_CORRELATE,
    ['REQ_RELAXED'] = 			constants.ZMQ_REQ_RELAXED,
    ['CONFLATE'] = 				constants.ZMQ_CONFLATE,
    ['ZAP_DOMAIN'] =			constants.ZMQ_ZAP_DOMAIN,
}

local socket_options = {
    [constants.ZMQ_AFFINITY] =				'i',
    [constants.ZMQ_IDENTITY] =				's',
    [constants.ZMQ_SUBSCRIBE] =				's',
    [constants.ZMQ_UNSUBSCRIBE] =			's',
    [constants.ZMQ_RATE] =					'i',
    [constants.ZMQ_RECOVERY_IVL] =			'i',
    [constants.ZMQ_SNDBUF] =				'i',
    [constants.ZMQ_RCVBUF] =				'i',
    [constants.ZMQ_RCVMORE] =				'b',
    [constants.ZMQ_FD] =					'i',
    [constants.ZMQ_EVENTS] =				'i',
    [constants.ZMQ_TYPE] =					'i',
    [constants.ZMQ_LINGER] =				'i',
    [constants.ZMQ_RECONNECT_IVL] =			'i',
    [constants.ZMQ_BACKLOG] =				'i',
    [constants.ZMQ_RECONNECT_IVL_MAX] =		'i',
    [constants.ZMQ_MAXMSGSIZE] =			'i',
    [constants.ZMQ_SNDHWM] =				'i',
    [constants.ZMQ_RCVHWM] =				'i',
    [constants.ZMQ_MULTICAST_HOPS] =		'i',
    [constants.ZMQ_RCVTIMEO] =				'i',
    [constants.ZMQ_SNDTIMEO] =				'i',
    [constants.ZMQ_LAST_ENDPOINT] =			's',
    [constants.ZMQ_ROUTER_MANDATORY] =		'i',
    [constants.ZMQ_TCP_KEEPALIVE] =			'i',
    [constants.ZMQ_TCP_KEEPALIVE_CNT] =		'i',
    [constants.ZMQ_TCP_KEEPALIVE_IDLE] =	'i',
    [constants.ZMQ_TCP_KEEPALIVE_INTVL] =	'i',
    [constants.ZMQ_TCP_ACCEPT_FILTER] =		's',
    [constants.ZMQ_IMMEDIATE] =				'i',
    [constants.ZMQ_XPUB_VERBOSE] =			'i',
    [constants.ZMQ_ROUTER_RAW] =			'b',
    [constants.ZMQ_IPV6] =					'b',
    [constants.ZMQ_MECHANISM] =				'i',
    [constants.ZMQ_PLAIN_SERVER] =			'b',
    [constants.ZMQ_PLAIN_USERNAME] =		's',
    [constants.ZMQ_PLAIN_PASSWORD] =		's',
    [constants.ZMQ_CURVE_SERVER] =			'b',
    [constants.ZMQ_CURVE_PUBLICKEY] =		's',
    [constants.ZMQ_CURVE_SECRETKEY] =		's',
    [constants.ZMQ_CURVE_SERVERKEY] =		's',
    [constants.ZMQ_PROBE_ROUTER] =			'i',
    [constants.ZMQ_REQ_CORRELATE] =			'b',
    [constants.ZMQ_REQ_RELAXED] =			'b',
    [constants.ZMQ_CONFLATE] =				'b',
    [constants.ZMQ_ZAP_DOMAIN] =			's',
}

local setupSocket

M.context = function(context, io_threads)
	local contextOwner
	if context then
		contextOwner = false
	else
		contextOwner = true
	end
	local context, msg = context or assert(zmq.init(io_threads))
	
	if not context then
		return false, msg
	end

	local options = {}
	setmetatable(options, {
		__index = function(t, name)
			return zmq.get(context, name)
		end,
		__newindex = function(t, name, value)
			zmq.set(context, name, value)
		end,
	})

	local lfn = {
		socket = function(_type)
			local socket, msg = zmq.socket(context, _type)
			if not socket then
				return false, msg
			end

			function setupSocket(socket)
				local socket = socket
				local closed = false
				local options = {}
		
				setmetatable(options, {
					__index = function(t, name)
						local index
						if type(name)=="number" then
							index = name
						elseif type(name) == "string" then
							index = socket_option_names[string.upper(name)]
						end

						local _type = socket_options[index]
						if _type then
							if _type == 'i' then
								return assert(zmq.socketGetOptionI(socket, index))
							elseif _type == 's' then
								return assert(zmq.socketGetOptionS(socket, index))
							elseif _type == 'b' then
								return assert(zmq.socketGetOptionI(socket, index) == 1)
							else
								error('Unknown socket option')
							end
						end
					end,
					__newindex = function(t, name, value)
						local index
						if type(name)=="number" then
							index = name
						elseif type(name) == "string" then
							index = socket_option_names[string.upper(name)]
						end

						local _type = socket_options[index]
						if _type then
							if _type == 'i' then
								return assert(zmq.socketSetOption(socket, index, tonumber(value)))
							elseif _type == 's' then
								return assert(zmq.socketSetOption(socket, index, tostring(value)))
							elseif _type == 'b' then
								return assert(zmq.socketSetOption(socket, index, (value and 1) or 0))
							end
						end
					end,
				})

				local lfn = {
					connect = function(endpoint)
						return zmq.connect(socket, endpoint)
					end,
					diconnect = function(endpoint)
						return zmq.disconnect(socket, endpoint)
					end,
					bind = function(endpoint)
						return zmq.bind(socket, endpoint)
					end,
					unbind = function(endpoint)
						return zmq.unbind(socket, endpoint)
					end,
					recv = function(len, flags)
						return zmq.recv(socket, len, flags)
					end,
					recvAll = function(flags)
						return zmq.recvAll(socket, flags)
					end,
					send = function(str, flags)
						local str = str or ''
						return zmq.send(socket, str, flags)
					end,
					recvMultipart = function(bufferLength)
						local bufferLength = bufferLength or 4096
						local results = {}

						repeat
							table.insert(results, assert(zmq.recv(socket, bufferLength)))
						until not socket.more
						return results
					end,
					sendMultipart = function(t, flags)
						local count = #t
						for i=1,count-1 do
							zmq.send(socket, t[i], constants.ZMQ_SNDMORE)
						end
						return zmq.send(socket, t[count], flags)
					end,
					sendID = function(id)
						if id then
							zmq.send(socket, id, constants.ZMQ_SNDMORE)
						end
						zmq.send(socket, '', constants.ZMQ_SNDMORE)
					end,
					close = function()
						if not closed then
							zmq.close(socket)
							closed = true
						end
					end,
					msg = function(size)
						local zmsg,msg
						if type(size)=="string" then
							zmsg,msg = zmq.msgInit(#size)
							if zmsg then
							   zmq.msgSetData(zmsg, size)
							end
						elseif type(size) == "number" then
							zmsg,msg = zmq.msgInit(size)
						else
							zmsg,msg = zmq.msgInit()
						end
						if not zmsg then
							return false, msg
						end

						local options = {}
						setmetatable(options, {
							__index = function(t, name)
								return zmq.msgGet(zmsg, name)
							end,
							__newindex = function(t, name, value)
								zmq.msgSet(zmsg, name, value)
							end,						
						})

						local lfn = {
							options = options,

							copy = function(dest)
								return zmq.msgCopy(zmsg, dest)
							end,
							move = function(dest)
								return zmq.msgMove(zmsg, dest)
							end,
							send = function(flags)
								return zmq.msgSend(zmsg, socket, flags)
							end,
							recv = function(flags)
								return zmq.msgRecv(zmsg, socket, flags)
							end,
						}

						local mt = getmetatable(zmsg)
						mt.__index = function(t, fn)
							if (fn == "size") then
								return zmq.msgSize(zmsg)
							elseif (fn == "more") then
								return (zmq.msgMore(zmsg) == 1)
							elseif (fn == "data") then
								return zmq.msgGetData(zmsg)
							else
								return lfn[fn]
							end
						end
						mt.__newindex = function(t, name, value)
							if name == "data" then
								zmq.msgSetData(zmsg, value)
							end
						end
						mt.__gc = function()
							zmq.msgClose(zmsg)
						end

						return zmsg
					end,
					options = options,
				}

				local mt = getmetatable(socket)
				mt.__index = function(t, fn)
					if fn == "more" then
						local more = zmq.socketGetOptionI(socket, constants.ZMQ_RCVMORE)
						return (more == 1)
					else
						return lfn[fn]
					end
				end
				mt.__newindex = function()
				end
				mt.__gc = function()
					lfn.close()
				end
				return socket
			end

			return setupSocket(socket)
		end,
		shutdown = function()
			zmq.shutdown(context)
		end,
		thread = function(code)
			local thread = zmq.thread(context, code)
			local mt = getmetatable(thread)
			local lfn = {
				join = function()
					zmq.joinThread(thread)
				end,
				result = function()
					return zmq.getThreadResult(thread)
				end
			}
			mt.__index = function(t, fn)
				return lfn[fn]
			end
			mt.__gc = function()
				zmq.freeThread(thread)
			end

			return thread
		end,
		pipe = function(id, pairType)
			local pair = assert(context.socket(constants.ZMQ_PAIR))
			pair.options.LINGER = 0
			pair.options.SNDHWM = 1
			pair.options.RCVHWM = 1

			if pairType=="bind" then
				pair.bind("inproc://"..id)
			elseif pairType=="connext" then
				pair.connect("inproc://"..id)
			end
			return pair
		end,
		options = options,
	}
	local mt = getmetatable(context)
	mt.__index = function(t, fn)
		return lfn[fn]
	end
	mt.__gc = function()
		if contextOwner then
			zmq.term(context)
		end
	end
	return context
end

M.version = function()
	return zmq.version()
end

M.sleep = function(n)
	zmq.sleep(n)
end

M.stopwatch = function()
	local stopwatch = zmq.stopwatchStart()
	local closed = false
	local lfs = {
		stop = function()
			if not closed then
				closed = true
				return zmq.stopwatchStop(stopwatch)
			end
		end,
	}
	local mt = getmetatable(stopwatch)
	mt.__index = function(t, fn)
		return lfn[fn]
	end
	mt.__gc = function()
		lfs.stop()
	end
end

M.poll = function()
	local poll = zmq.pollNew()
	local pollItems = {}
	setmetatable(pollItems, { __mode = 'k'})
	local items = {}

	setmetatable(items, {
		__index = function(t, id)
			local v = zmq.pollGet(poll, id)
			if v then
				local s = v.socket
				local i = pollItems[s]
				return {socket = s, revents = v.revents, flags = i[1], fn = i[2]}
			end
		end,
		__newindex = function(t, id, v)
			local s = v.socket
			local flags = v.flags
			pollItems[s] = {flags, v.fn}
			zmq.pollSet(poll, id, {socket = s, fd = 0, events = flags, revents = 0})
		end,
		__len = function(t)
			return zmq.pollSize(poll)
		end,
	})

	local lfn = {
		items = items,
		start = function(timeout)
			if assert(zmq.poll(poll, timeout)) > 0 then
				local size = zmq.pollSize(poll)
				for i=0,size-1 do
					local v = zmq.pollGet(poll, i) 
					if v then
						local s = v.socket
						local pollItem = pollItems[s]
						if pollItem then
							if bit.band(v.revents, pollItem[1]) > 0 then
								local flags = pollItem[1]
								local fn = pollItem[2]
								if type(fn) == "function" then
									fn(s)
								end
							end
						end
					end
				end
			end
		end,
		add = function(s, flags, fn)
			pollItems[s] = {flags, fn}
			zmq.pollSet(poll,
				{socket = s, fd = 0, events = flags, revents = 0}
			)
		end,
	}

	local mt = getmetatable(poll)
	mt.__index = function(t, fn)
		return lfn[fn]
	end
	mt.__gc = function()
		zmq.pollFree(poll)
	end
	return poll
end

M.proxy = function(forward, backend, capture)
	zmq.proxy(forward, backend, capture)
end

M.tohex = function(s)
	local t = {}
	for i=1,#s do
		table.insert(t, string.format("%02X", string.byte(s, i)))
	end
	return table.concat(t)
end

setmetatable(M, {
	__index = constants,
	__newindex = function(t, n, v)
	end,
})

return M