local function tryRequire(moduleName)
	local status, M = pcall(function(m) return require(m) end, moduleName)
	if not status then
		return nil, M
	else
		return M
	end
end

local bit = tryRequire('bit3') or tryRequire('bit') or tryRequire('bit32')
local bit2 = require 'numberlua'

local band = bit.band

local function memoize(f)
  local mt = {}
  local t = setmetatable({}, mt)
  function mt:__index(k)
    local v = f(k); t[k] = v
    return v
  end
  return t
end

local function make_bitop_uncached(t, m)
  local function bitop(a, b)
    local res,p = 0,1
    while a ~= 0 and b ~= 0 do
      local am, bm = a%m, b%m
      res = res + t[am][bm]*p
      a = (a - am) / m
      b = (b - bm) / m
      p = p*m
    end
    res = res + (a+b)*p
    return res
  end
  return bitop
end

local function make_bitop(t)
  local op1 = make_bitop_uncached(t,2^1)
  local op2 = memoize(function(a)
    return memoize(function(b)
      return op1(a, b)
    end)
  end)
  return make_bitop_uncached(op2, 2^(t.n or 1))
end


local bxor = make_bitop {[0]={[0]=0,[1]=1},[1]={[0]=1,[1]=0}, n=4}

local function band2(a,b) return ((a+b) - bxor(a,b))/2 end

local a = 0x0102
local b = 0x0100

for _, fn in ipairs{band, band2} do
	if type(fn)=='function' then
		print(('%04X'):format(fn(a, b)))
	end
end