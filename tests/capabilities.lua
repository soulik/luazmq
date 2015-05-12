local zmq = require 'luazmq'

print('A list of supported capabilities:')

for _, capability in ipairs {
	'ipc', 'pgm', 'tipc', 'norm', 'curve', 'gssapi',
} do
	print(("%s : %s"):format(capability, zmq.has(capability) and "true" or "false"))
end
