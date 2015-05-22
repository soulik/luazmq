/*
	LuaZMQ - Lua binding for ZeroMQ library

	Copyright 2013, 2014, 2015 Mário Kašuba
	All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are
	met:

	* Redistributions of source code must retain the above copyright
	  notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright
	  notice, this list of conditions and the following disclaimer in the
	  documentation and/or other materials provided with the distribution.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
	OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
	LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
	THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <zmq.h>
#include <zmq_utils.h>

#include <lutok2/lutok2.hpp>
using namespace lutok2;

#if (BUILDING_LIBLUAZMQ || luazmq_EXPORTS) && HAVE_VISIBILITY
#define LIBLUAZMQ_DLL_EXPORTED __attribute__((visibility("default")))
#elif (BUILDING_LIBLUAZMQ || luazmq_EXPORTS) && defined _MSC_VER
#define LIBLUAZMQ_DLL_EXPORTED __declspec(dllexport)
#elif defined _MSC_VER
#define LIBLUAZMQ_DLL_EXPORTED __declspec(dllimport)
#else
#define LIBLUAZMQ_DLL_EXPORTED
#endif

#ifndef _MSC_VER

#define _alloca	alloca

#endif