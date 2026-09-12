#pragma once

#ifndef LUA_OK
#define LUA_OK 0
#endif

#ifndef XRAY_USE_LUAJIT
typedef void (*luaJIT_profile_callback)(void* data, lua_State* L, int samples, int vmstate);
#define LUA_BITLIBNAME "bit"
#define LUA_FFILIBNAME "ffi"
#define LUA_JITLIBNAME "jit"
inline void luaopen_bit(lua_State*) {}
inline void luaopen_ffi(lua_State*) {}
inline void luaopen_jit(lua_State*) {}
#endif
