--[[
   ___ _         _       ___         _          _   _           __   ___    
  / __| |_  _ __| |___  | _ \_ _ ___| |_ ___ __| |_(_)___ _ _   \ \ / / |    
 | (__| | || / _` / -_) |  _/ '_/ _ \  _/ -_) _|  _| / _ \ ' \   \ V /| |  
  \___|_|\_, \__,_\___| |_| |_| \___/\__\___\__|\__|_\___/_||_|   \_/ |_|   
         |__/   
  
  https://clydeprotectionde.cloud   
  build 7756E1A1  
]]
local _genv=(type(getgenv)=="function" and getgenv())or(type(getfenv)=="function" and getfenv(0))or _G
local _env=setmetatable({print=print,warn=warn,error=error,assert=assert,type=type,typeof=typeof,tostring=tostring,tonumber=tonumber,pcall=pcall,xpcall=xpcall,select=select,unpack=unpack,pairs=pairs,ipairs=ipairs,next=next,rawget=rawget,rawset=rawset,rawequal=rawequal,rawlen=rawlen,setmetatable=setmetatable,getmetatable=getmetatable,string=string,table=table,math=math,bit32=bit32,coroutine=coroutine,os=os,debug=debug,utf8=utf8,buffer=buffer,game=game,workspace=workspace,script=script,Instance=Instance,Vector3=Vector3,Vector2=Vector2,CFrame=CFrame,Color3=Color3,BrickColor=BrickColor,UDim=UDim,UDim2=UDim2,Enum=Enum,Ray=Ray,Region3=Region3,Rect=Rect,TweenInfo=TweenInfo,NumberSequence=NumberSequence,ColorSequence=ColorSequence,NumberRange=NumberRange,Random=Random,DateTime=DateTime,RaycastParams=RaycastParams,OverlapParams=OverlapParams,tick=tick,time=time,wait=wait,task=task,spawn=spawn,delay=delay,require=require,loadstring=loadstring,load=load,getfenv=getfenv,setfenv=setfenv,newproxy=newproxy,_G=_G,shared=shared,settings=settings,stats=stats,UserSettings=UserSettings,version=version},{__index=function(_,k) local ok,v=pcall(function() return _genv[k] end)
if ok then return v end
return nil end})

local function _run(K,code,_env,protos,initLocals,upvalues,varargs)
protos=protos or {}
upvalues=upvalues or {}
varargs=varargs or {}
local varargCount=varargs.n or #varargs
local function resolveK(_idx) return K[_idx] end
local stack={}
local locals={}
local callBases={}
local stackTop=0
local localBoxes={}
local ip=1
local callBaseTop=0
local _doReturn=false
local _retFromStack=false
local _retBase=0
local _retTop=0
local _retN=0
local _retPack=nil
local ctxBit=0
if initLocals then for _k=0,(initLocals.n or 0)-1 do locals[_k]=initLocals[_k] end end
local function push(v) stackTop=stackTop+1
stack[stackTop]=v end
local function pop() local v=stack[stackTop]
stack[stackTop]=nil
stackTop=stackTop-1
return v end
local function top() return stack[stackTop] end
local function getLocal(slot) local box=localBoxes[slot]
if box then return box[1] end
return locals[slot] end
local function setLocal(slot,val) local box=localBoxes[slot]
if box then box[1]=val else locals[slot]=val end end
local function boxLocal(slot) if not localBoxes[slot] then localBoxes[slot]={locals[slot]} end
return localBoxes[slot] end
local function getMM(obj,name) local ok,mt=pcall(getmetatable,obj)
if ok and mt and type(mt)=="table" then return rawget(mt,name) end
return nil end
local function arithMM(a,b,op,name) if type(a)=="number" and type(b)=="number" then return op(a,b) end
local ok,r=pcall(op,a,b)
if ok then return r end
local mm=getMM(a,name) or getMM(b,name)
if mm then return mm(a,b) end
return op(a,b) end
local handlers={}
handlers[0]=function() end
handlers[1]=function() push(nil) end
handlers[2]=function() push(true) end
handlers[3]=function() push(false) end
handlers[4]=function() push(resolveK(code[ip]+1))
ip=ip+1 end
handlers[5]=function() push(getLocal(code[ip]))
ip=ip+1 end
handlers[6]=function() setLocal(code[ip],pop())
ip=ip+1 end
handlers[7]=function() push(_env[resolveK(code[ip]+1)])
ip=ip+1 end
handlers[8]=function() _env[resolveK(code[ip]+1)]=pop()
ip=ip+1 end
handlers[9]=function() local b,a=pop(),pop()
push(arithMM(a,b,function(x,y) return x+y end,"__add")) end
handlers[10]=function() local b,a=pop(),pop()
push(arithMM(a,b,function(x,y) return x-y end,"__sub")) end
handlers[11]=function() local b,a=pop(),pop()
push(arithMM(a,b,function(x,y) return x*y end,"__mul")) end
handlers[12]=function() local b,a=pop(),pop()
push(arithMM(a,b,function(x,y) return x/y end,"__div")) end
handlers[13]=function() local b,a=pop(),pop()
push(arithMM(a,b,function(x,y) return x%y end,"__mod")) end
handlers[14]=function() local b,a=pop(),pop()
push(arithMM(a,b,function(x,y) return x^y end,"__pow")) end
handlers[15]=function() local b,a=pop(),pop()
local ok,r=pcall(function() return a..b end)
if ok then push(r) else push(tostring(a)..tostring(b)) end end
handlers[16]=function() local b,a=pop(),pop()
push(a==b) end
handlers[17]=function() local b,a=pop(),pop()
push(a~=b) end
handlers[18]=function() local b,a=pop(),pop()
push(a<b) end
handlers[19]=function() local b,a=pop(),pop()
push(a<=b) end
handlers[20]=function() local b,a=pop(),pop()
push(a>b) end
handlers[21]=function() local b,a=pop(),pop()
push(a>=b) end
handlers[22]=function() local b,a=pop(),pop()
push(a and b) end
handlers[23]=function() local b,a=pop(),pop()
push(a or b) end
handlers[24]=function() push(not pop()) end
handlers[25]=function() push(-pop()) end
handlers[26]=function() push(#pop()) end
handlers[27]=function() push({}) end
handlers[28]=function() local k,t=pop(),pop()
push(t[k]) end
handlers[29]=function() local v,k,t=pop(),pop(),pop()
t[k]=v end
handlers[30]=function() local n=code[ip]
ip=ip+1
local args={}
for i=1,n do args[n-i+1]=pop() end
local f=pop()
if type(f)~="function" then local mm=getMM(f,"__call")
if mm then table.insert(args,1,f)
n=n+1
f=mm else error("attempt to call a "..type(f).." value") end end
local r
if n==0 then r={f()} else r={f(table.unpack(args,1,n))} end
push(r[1]) end
handlers[31]=function() local n=code[ip]
ip=ip+1
_doReturn=true
if n==0 then _retN=0 elseif n>0 then if n>stackTop then n=stackTop end
_retN=n
_retFromStack=true
_retTop=stackTop
_retBase=stackTop-n else _retN=stackTop
_retFromStack=true
_retTop=stackTop
_retBase=0 end end
handlers[32]=function() ip=code[ip]+1 end
handlers[33]=function() local target=code[ip]
ip=ip+1
if not pop() then ip=target+1 end end
handlers[34]=function() local n=code[ip]
ip=ip+1
for _=1,n do pop() end end
handlers[35]=function() local pi=code[ip]
ip=ip+1
local P=protos[pi]
if P then
local _r,Kp,Cp=_run,P.K or K,P.C or {}
local nU={}
if P.U then for ui,ud in ipairs(P.U) do local iL,idx=ud[1],ud[2]
if iL==1 then nU[ui]=boxLocal(idx) else nU[ui]=upvalues[idx+1] end end end
local nP=P.nParams or 0
push(function(...)
local a={...}
local ac=select("#",...)
local L={}
L.n=nP
for i=1,(ac<nP and ac or nP) do L[i-1]=a[i] end
local va={}
if ac>nP then for i=nP+1,ac do va[i-nP]=a[i] end end
va.n=ac-nP
return _r(Kp,Cp,_env,P.P or {},L,nU,va)
end)
else push(nil) end end
handlers[36]=function() push(top()) end
handlers[37]=function() local ui=code[ip]
ip=ip+1
local box=upvalues[ui+1]
push(box and box[1] or nil) end
handlers[38]=function() local ui=code[ip]
ip=ip+1
local box=upvalues[ui+1]
if box then box[1]=pop() else pop() end end
handlers[39]=function() local na=code[ip]
ip=ip+1
local nr=code[ip]
ip=ip+1
local args={}
for i=1,na do args[na-i+1]=pop() end
local f=pop()
if type(f)~="function" then local mm=getMM(f,"__call")
if mm then table.insert(args,1,f)
na=na+1
f=mm else error("attempt to call a "..type(f).." value") end end
local r
if na==0 then r=table.pack(f()) else r=table.pack(f(table.unpack(args,1,na))) end
local rn=nr<0 and r.n or nr
for i=1,rn do push(r[i]) end end
handlers[40]=function() local n=code[ip]
ip=ip+1
if n<0 then for i=1,varargCount do push(varargs[i]) end else for i=1,n do push(varargs[i]) end end end
handlers[41]=function() local n=code[ip]
ip=ip+1
local args={}
for j=n,1,-1 do args[j]=pop() end
local f=pop()
if type(f)~="function" then local mm=getMM(f,"__call")
if mm then table.insert(args,1,f)
n=n+1
f=mm end end
_doReturn=true
_retPack=table.pack(f(table.unpack(args,1,n))) end
handlers[42]=function() local off=code[ip]
ip=ip+1
local step=pop()
local limit=pop()
local init=pop()
push(init)
push(limit)
push(step)
if step>=0 then if init>limit then ip=off+1 end else if init<limit then ip=off+1 end end end
handlers[43]=function() local off=code[ip]
ip=ip+1
local step=stack[stackTop]
local i=stack[stackTop-2]+step
stack[stackTop-2]=i
local limit=stack[stackTop-1]
if step>=0 then if i<=limit then ip=off+1 end else if i>=limit then ip=off+1 end end end
handlers[44]=function() local n=code[ip]
ip=ip+1
local parts={}
for i=1,n do parts[n-i+1]=tostring(pop()) end
push(table.concat(parts)) end
handlers[45]=function() local n=code[ip]
ip=ip+1
for _=1,n do push(nil) end end
handlers[46]=function() callBaseTop=callBaseTop+1
callBases[callBaseTop]=stackTop end
handlers[47]=function() local nr=code[ip]
ip=ip+1
local base=callBases[callBaseTop]
callBaseTop=callBaseTop-1
local f=stack[base+1]
local na=stackTop-base-1
local args={}
for i=1,na do args[i]=stack[base+1+i] end
stackTop=base
if type(f)~="function" then local mm=getMM(f,"__call")
if mm then table.insert(args,1,f)
na=na+1
f=mm else error("attempt to call a "..type(f).." value") end end
local r
if na==0 then r=table.pack(f()) else r=table.pack(f(table.unpack(args,1,na))) end
local rn=nr<0 and r.n or nr
for i=1,rn do push(r[i]) end end
handlers[48]=function() local b,a=pop(),pop()
push(arithMM(a,b,function(x,y) return math.floor(x/y) end,"__idiv")) end
handlers[49]=function() local slot=code[ip]
ip=ip+1
local box=localBoxes[slot]
if box then locals[slot]=box[1]
localBoxes[slot]=nil end end
handlers[50]=function() local startIdx=code[ip]
ip=ip+1
local base=callBases[callBaseTop]
callBaseTop=callBaseTop-1
local tbl=stack[base]
local idx=startIdx
for i=base+1,stackTop do tbl[idx]=stack[i]
idx=idx+1 end
stackTop=base
stack[stackTop]=tbl end
handlers[51]=function() local a=stack[stackTop]
stack[stackTop]=stack[stackTop-1]
stack[stackTop-1]=a end
handlers[52]=function() local nameIdx=code[ip]
ip=ip+1
local methodName=resolveK(nameIdx+1)
local obj=pop()
local method=obj[methodName]
push(obj)
push(method)
local b,a=pop(),pop()
push(b)
push(a) end
handlers[53]=function() local nVars=code[ip]
ip=ip+1
local target=code[ip]
ip=ip+1
local iter=stack[stackTop-2]
local state=stack[stackTop-1]
local ctl=stack[stackTop]
local r={iter(state,ctl)}
for i=1,nVars do push(r[i]) end
if r[1]~=nil then stack[stackTop-nVars]= r[1] else ip=target+1 end end
handlers[54]=function() local n=code[ip]
ip=ip+1
local args={}
for i=1,n do args[n-i+1]=pop() end
local f=pop()
local results
if n==0 then results=table.pack(pcall(f)) else results=table.pack(pcall(f,table.unpack(args,1,n))) end
local ok=results[1]
push(ok)
if ok then for i=2,results.n do push(results[i]) end else push(results[2]) end end
handlers[55]=function() local n=code[ip]
ip=ip+1
local args={}
for i=1,n do args[n-i+1]=pop() end
local handler=pop()
local f=pop()
local results
if n==0 then results=table.pack(xpcall(f,handler)) else results=table.pack(xpcall(f,handler,table.unpack(args,1,n))) end
local ok=results[1]
push(ok)
for i=2,results.n do push(results[i]) end end
handlers[56]=function() local iS=code[ip]
ip=ip+1
local sS=code[ip]
ip=ip+1
local vS=code[ip]
ip=ip+1
local it=getLocal(iS)
if type(it)=="table" then local ok2,mt=pcall(getmetatable,it)
if ok2 and type(mt)=="table" and mt.__iter then local fn=mt.__iter(it)
setLocal(iS,fn) elseif ok2 and type(mt)=="table" and mt.__call then else setLocal(iS,next)
setLocal(sS,it)
setLocal(vS,nil) end end end
handlers[57]=function() local a=code[ip]
ip=ip+1
local b=code[ip]
ip=ip+1
local c=code[ip]
ip=ip+1
setLocal(c,getLocal(a)+getLocal(b)) end
handlers[58]=function() local a=code[ip]
ip=ip+1
local b=code[ip]
ip=ip+1
local c=code[ip]
ip=ip+1
setLocal(c,getLocal(a)-getLocal(b)) end
handlers[59]=function() local a=code[ip]
ip=ip+1
local b=code[ip]
ip=ip+1
local c=code[ip]
ip=ip+1
setLocal(c,getLocal(a)*getLocal(b)) end
handlers[60]=function() local k=code[ip]
ip=ip+1
local s=code[ip]
ip=ip+1
setLocal(s,resolveK(k+1)) end
handlers[61]=function() local a=code[ip]
ip=ip+1
local b=code[ip]
ip=ip+1
setLocal(b,getLocal(a)) end
handlers[62]=function() local a=code[ip]
ip=ip+1
local k=code[ip]
ip=ip+1
local c=code[ip]
ip=ip+1
setLocal(c,getLocal(a)+resolveK(k+1)) end
handlers[63]=function() local a=code[ip]
ip=ip+1
local b=code[ip]
ip=ip+1
local c=code[ip]
ip=ip+1
setLocal(c,getLocal(a)..getLocal(b)) end
handlers[64]=function() local _=stackTop end
handlers[65]=function() local _a=code[ip]
ip=ip+1
local _=stack[_a] or 0 end
handlers[66]=function() local _a=code[ip]
ip=ip+1
local _b=code[ip]
ip=ip+1
local _=bit32.bxor(_a,_b) end
handlers[67]=function() local _a=code[ip]
ip=ip+1
if ctxBit==0 then push(getLocal(_a)) else push(resolveK(_a+1)) end end
while true do
if _doReturn or ip>#code then break end
local op=code[ip]
ip=ip+1
local h=handlers[op]
if h then h() end
end
if _doReturn then
if _retPack then return table.unpack(_retPack,1,_retPack.n or #_retPack) end
if _retFromStack then
if _retN==0 then return end
return table.unpack(stack,_retBase+1,_retTop)
end
return
end
return nil
end
local _0O_3={4,0,6,0,46,7,1,7,2,36,4,3,28,51,5,0,4,4,15,39,2,-1,47,1,30,0,6,1,46,7,1,7,2,36,4,3,28,51,5,0,4,5,15,39,2,-1,47,1,30,0,6,2,46,7,1,7,2,36,4,3,28,51,5,0,4,6,15,39,2,-1,47,1,30,0,6,3,4,7,6,4,4,8,6,5,4,9,6,6,4,10,6,7,4,11,6,8,7,2,36,4,12,28,51,4,13,30,2,6,9,7,2,36,4,12,28,51,4,14,30,2,6,10,7,2,36,4,12,28,51,4,15,30,2,6,11,7,2,36,4,12,28,51,4,16,30,2,6,12,7,2,36,4,12,28,51,4,17,30,2,6,13,5,9,4,18,28,6,14,7,19,7,2,4,20,28,30,1,6,15,27,36,4,21,3,29,36,4,22,27,36,4,23,2,29,36,4,24,4,25,29,36,4,26,7,27,4,28,28,4,29,4,30,4,30,30,3,29,36,4,31,4,32,29,36,4,33,3,29,36,4,34,3,29,36,4,35,3,29,36,4,36,3,29,29,36,4,37,27,36,4,23,3,29,36,4,26,7,27,4,28,28,4,29,4,30,4,30,30,3,29,36,4,38,4,39,29,29,36,4,40,27,36,4,41,3,29,36,4,42,3,29,36,4,43,3,29,36,4,44,3,29,36,4,45,3,29,36,4,46,7,27,4,28,28,4,29,4,29,4,29,30,3,29,36,4,47,7,27,4,28,28,4,29,4,29,4,29,30,3,29,36,4,48,7,27,4,28,28,4,29,4,29,4,29,30,3,29,36,4,49,4,50,29,36,4,51,4,52,29,29,36,4,53,27,36,4,23,3,29,36,4,54,7,27,4,28,28,4,30,4,30,4,30,30,3,29,36,4,55,7,27,4,28,28,4,29,4,29,4,29,30,3,29,29,36,4,34,27,36,4,56,3,29,36,4,57,3,29,36,4,58,3,29,36,4,59,3,29,36,4,60,3,29,36,4,61,3,29,36,4,62,4,63,29,29,36,4,64,27,36,4,23,3,29,36,4,35,3,29,36,4,26,7,27,4,28,28,4,29,4,30,4,30,30,3,29,36,4,65,4,66,29,36,4,67,2,29,36,4,68,7,27,4,28,28,4,29,4,29,4,29,30,3,29,36,4,69,4,30,29,36,4,70,2,29,29,36,4,71,27,36,4,23,3,29,36,4,35,3,29,36,4,72,3,29,36,4,26,7,27,4,28,28,4,29,4,30,4,30,30,3,29,36,4,31,4,73,29,36,4,65,4,73,29,36,4,74,4,75,29,29,36,4,76,27,36,4,23,3,29,36,4,77,4,78,29,36,4,79,4,80,29,36,4,81,4,82,29,36,4,83,4,84,29,36,4,85,4,86,29,36,4,87,4,88,29,36,4,89,2,29,36,4,90,2,29,36,4,33,3,29,36,4,21,3,29,36,4,91,3,29,36,4,92,4,30,29,36,4,93,7,27,4,28,28,4,29,4,30,4,30,30,3,29,36,4,94,7,27,4,28,28,4,30,4,29,4,30,30,3,29,36,4,95,3,29,36,4,96,4,97,29,36,4,98,3,29,36,4,99,4,30,29,36,4,100,27,29,36,4,101,27,29,29,6,16,35,1,6,17,5,17,5,4,4,102,30,2,6,18,5,17,5,5,4,64,30,2,6,19,5,17,5,6,4,71,30,2,6,20,5,17,5,7,4,76,30,2,6,21,46,7,1,7,2,36,4,3,28,51,5,8,39,2,-1,47,1,30,0,6,22,5,18,4,103,28,27,36,4,13,5,9,29,36,4,14,5,10,29,36,4,15,5,11,29,36,4,104,5,14,29,36,4,105,5,16,29,36,4,17,5,13,29,36,4,106,5,22,29,30,1,6,23,5,19,4,103,28,27,36,4,13,5,9,29,36,4,14,5,10,29,36,4,15,5,11,29,36,4,104,5,14,29,36,4,105,5,16,29,36,4,106,5,22,29,30,1,6,24,5,20,4,103,28,27,36,4,13,5,9,29,36,4,14,5,10,29,36,4,15,5,11,29,36,4,104,5,14,29,36,4,105,5,16,29,36,4,106,5,22,29,30,1,6,25,5,21,4,103,28,27,36,4,13,5,9,29,36,4,14,5,10,29,36,4,15,5,11,29,36,4,104,5,14,29,36,4,17,5,13,29,36,4,105,5,16,4,76,28,29,36,4,106,5,22,29,30,1,6,26,3,6,27,4,30,6,28,27,6,29,4,30,6,30,27,6,31,3,6,32,27,6,33,1,6,34,27,36,4,107,27,36,4,108,4,109,29,36,4,110,4,111,29,29,36,4,112,27,36,4,108,4,113,29,36,4,110,4,114,29,29,6,35,35,2,6,36,35,3,6,37,35,4,6,38,35,5,6,39,3,6,40,27,6,41,4,115,6,42,4,30,6,43,27,6,44,3,6,45,4,116,6,46,4,117,6,47,4,66,6,48,4,30,6,49,4,30,6,50,4,30,6,51,1,6,52,1,6,53,1,6,54,3,6,55,3,6,56,4,30,6,57,7,118,4,103,28,30,0,6,58,35,6,6,59,35,7,6,60,35,8,6,61,35,9,6,62,35,10,6,63,35,11,6,64,35,12,6,65,35,13,6,66,35,14,6,67,35,15,6,68,35,16,6,69,35,17,6,70,35,18,6,71,35,19,6,72,35,20,6,73,35,21,6,74,35,22,6,75,35,23,6,76,35,24,6,77,35,25,6,78,35,26,6,79,35,27,6,80,35,28,6,81,35,29,6,82,35,30,6,83,35,31,6,84,35,32,6,85,35,33,6,86,35,34,6,87,35,35,6,88,35,36,6,89,35,37,6,90,5,1,36,4,119,28,51,27,36,4,120,4,121,29,36,4,122,2,29,36,4,123,2,29,30,2,6,91,27,36,4,124,5,91,36,4,125,28,51,4,124,30,2,29,36,4,126,5,91,36,4,125,28,51,4,126,30,2,29,36,4,76,5,91,36,4,125,28,51,4,76,30,2,29,36,4,127,5,91,36,4,125,28,51,4,127,30,2,29,6,92,5,92,4,124,28,36,4,128,28,51,4,126,30,2,6,93,5,92,4,124,28,36,4,129,28,51,4,130,30,2,6,94,5,93,36,4,131,28,51,4,132,27,36,4,58,4,133,29,36,4,134,3,29,30,3,34,1,7,135,4,132,28,36,4,136,28,51,35,38,30,2,34,1,5,93,36,4,137,28,51,4,138,27,36,4,58,4,139,29,36,4,134,4,30,29,36,4,140,4,30,29,36,4,141,4,73,29,36,4,142,4,32,29,36,4,143,3,29,30,3,34,1,7,144,4,138,28,36,4,136,28,51,35,39,30,2,34,1,5,93,36,4,131,28,51,4,145,27,36,4,58,4,146,29,36,4,134,3,29,30,3,34,1,7,135,4,145,28,36,4,136,28,51,35,40,30,2,34,1,5,92,4,124,28,36,4,128,28,51,4,147,30,2,6,95,5,95,36,4,131,28,51,4,148,27,36,4,58,4,23,29,36,4,134,3,29,30,3,34,1,7,135,4,148,28,36,4,136,28,51,35,41,30,2,34,1,5,95,36,4,137,28,51,4,149,27,36,4,58,4,150,29,36,4,134,4,116,29,36,4,140,4,151,29,36,4,141,4,73,29,36,4,142,4,32,29,36,4,143,3,29,30,3,34,1,7,144,4,149,28,36,4,136,28,51,35,42,30,2,34,1,5,95,36,4,137,28,51,4,152,27,36,4,58,4,153,29,36,4,134,4,117,29,36,4,140,4,30,29,36,4,141,4,117,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,152,28,36,4,136,28,51,35,43,30,2,34,1,5,95,36,4,137,28,51,4,154,27,36,4,58,4,155,29,36,4,134,4,66,29,36,4,140,4,30,29,36,4,141,4,73,29,36,4,142,4,32,29,36,4,143,3,29,30,3,34,1,7,144,4,154,28,36,4,136,28,51,35,44,30,2,34,1,5,95,36,4,131,28,51,4,156,27,36,4,58,4,157,29,36,4,134,3,29,30,3,34,1,7,135,4,156,28,36,4,136,28,51,35,45,30,2,34,1,5,95,36,4,131,28,51,4,158,27,36,4,58,4,159,29,36,4,134,3,29,30,3,34,1,7,135,4,158,28,36,4,136,28,51,35,46,30,2,34,1,5,94,36,4,131,28,51,4,160,27,36,4,58,4,161,29,36,4,134,3,29,30,3,34,1,7,135,4,160,28,36,4,136,28,51,35,47,30,2,34,1,5,94,36,4,131,28,51,4,162,27,36,4,58,4,163,29,36,4,134,3,29,30,3,34,1,7,135,4,162,28,36,4,136,28,51,35,48,30,2,34,1,5,94,36,4,131,28,51,4,164,27,36,4,58,4,165,29,36,4,134,3,29,30,3,34,1,7,135,4,164,28,36,4,136,28,51,35,49,30,2,34,1,5,94,36,4,131,28,51,4,166,27,36,4,58,4,167,29,36,4,134,3,29,30,3,34,1,7,135,4,166,28,36,4,136,28,51,35,50,30,2,34,1,5,92,4,126,28,36,4,128,28,51,4,22,30,2,6,96,5,96,36,4,131,28,51,4,168,27,36,4,58,4,23,29,36,4,134,5,16,4,22,28,4,23,28,29,30,3,34,1,7,135,4,168,28,36,4,136,28,51,35,51,30,2,34,1,5,96,36,4,169,28,51,4,170,27,36,4,171,27,36,4,73,4,25,29,36,4,32,4,80,29,29,36,4,134,4,73,29,36,4,172,3,29,36,4,58,4,173,29,30,3,34,1,7,144,4,170,28,36,4,136,28,51,35,52,30,2,34,1,5,96,36,4,174,28,51,4,175,30,2,36,4,176,28,51,4,177,27,36,4,134,5,16,4,22,28,4,26,28,29,36,4,120,4,175,29,30,3,34,1,7,144,4,177,28,36,4,136,28,51,35,53,30,2,34,1,5,96,36,4,131,28,51,4,178,27,36,4,58,4,35,29,36,4,134,5,16,4,22,28,4,35,28,29,30,3,34,1,7,135,4,178,28,36,4,136,28,51,35,54,30,2,34,1,5,96,36,4,131,28,51,4,179,27,36,4,58,4,180,29,36,4,134,5,16,4,22,28,4,33,28,29,30,3,34,1,7,135,4,179,28,36,4,136,28,51,35,55,30,2,34,1,5,96,36,4,131,28,51,4,181,27,36,4,58,4,182,29,36,4,134,5,16,4,21,28,29,30,3,34,1,7,135,4,181,28,36,4,136,28,51,35,56,30,2,34,1,5,96,36,4,131,28,51,4,183,27,36,4,58,4,184,29,36,4,134,5,16,4,22,28,4,36,28,29,30,3,34,1,7,135,4,183,28,36,4,136,28,51,35,57,30,2,34,1,5,96,36,4,137,28,51,4,185,27,36,4,58,4,186,29,36,4,134,5,16,4,22,28,4,31,28,29,36,4,140,4,73,29,36,4,141,4,187,29,36,4,142,4,73,29,36,4,143,3,29,30,3,34,1,7,144,4,185,28,36,4,136,28,51,35,58,30,2,34,1,5,92,4,126,28,36,4,129,28,51,4,37,30,2,6,97,5,97,36,4,131,28,51,4,188,27,36,4,58,4,189,29,36,4,134,5,16,4,37,28,4,23,28,29,30,3,6,98,5,98,36,4,176,28,51,4,190,27,36,4,134,5,16,4,37,28,4,26,28,29,36,4,120,4,191,29,30,3,34,1,7,135,4,188,28,36,4,136,28,51,35,59,30,2,34,1,7,144,4,190,28,36,4,136,28,51,35,60,30,2,34,1,5,97,36,4,137,28,51,4,192,27,36,4,58,4,193,29,36,4,134,7,194,4,195,28,4,73,5,16,4,37,28,4,38,28,10,4,84,11,30,1,29,36,4,140,4,30,29,36,4,141,4,84,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,192,28,36,4,136,28,51,35,61,30,2,34,1,5,92,4,126,28,36,4,129,28,51,4,64,30,2,6,99,5,92,4,126,28,36,4,129,28,51,4,196,30,2,6,100,5,100,36,4,169,28,51,4,197,27,36,4,171,27,36,4,73,4,198,29,36,4,32,4,199,29,36,4,200,4,58,29,36,4,201,4,202,29,36,4,86,4,203,29,29,36,4,134,27,36,4,198,5,16,4,34,28,4,56,28,29,36,4,199,5,16,4,34,28,4,57,28,29,36,4,58,5,16,4,34,28,4,58,28,29,36,4,202,5,16,4,34,28,4,59,28,29,36,4,203,5,16,4,34,28,4,60,28,29,29,36,4,172,2,29,36,4,58,4,204,29,30,3,34,1,7,144,4,197,28,36,4,136,28,51,35,62,30,2,34,1,5,100,36,4,131,28,51,4,205,27,36,4,58,4,206,29,36,4,134,5,16,4,34,28,4,61,28,29,30,3,34,1,7,135,4,205,28,36,4,136,28,51,35,63,30,2,34,1,5,100,36,4,137,28,51,4,207,27,36,4,58,4,208,29,36,4,134,5,16,4,34,28,4,62,28,29,36,4,140,4,30,29,36,4,141,4,84,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,207,28,36,4,136,28,51,35,64,30,2,34,1,5,99,36,4,131,28,51,4,209,27,36,4,58,4,23,29,36,4,134,5,16,4,64,28,4,23,28,29,30,3,6,101,5,101,36,4,176,28,51,4,210,27,36,4,134,5,16,4,64,28,4,26,28,29,36,4,120,4,211,29,36,4,212,35,65,29,30,3,34,1,5,101,36,4,136,28,51,35,66,30,2,34,1,5,99,36,4,131,28,51,4,213,27,36,4,58,4,35,29,36,4,134,5,16,4,64,28,4,35,28,29,30,3,34,1,7,135,4,213,28,36,4,136,28,51,35,67,30,2,34,1,5,99,36,4,137,28,51,4,214,27,36,4,58,4,65,29,36,4,134,7,194,4,195,28,5,16,4,64,28,4,65,28,4,84,11,30,1,29,36,4,140,4,30,29,36,4,141,4,84,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,214,28,36,4,136,28,51,35,68,30,2,34,1,5,99,36,4,131,28,51,4,215,27,36,4,58,4,67,29,36,4,134,5,16,4,64,28,4,67,28,29,30,3,6,102,5,102,36,4,176,28,51,4,216,27,36,4,134,5,16,4,64,28,4,68,28,29,36,4,120,4,217,29,36,4,212,35,69,29,30,3,34,1,7,135,4,215,28,36,4,136,28,51,35,70,30,2,34,1,5,99,36,4,137,28,51,4,218,27,36,4,58,4,219,29,36,4,134,7,194,4,195,28,5,16,4,64,28,4,69,28,4,84,11,30,1,29,36,4,140,4,30,29,36,4,141,4,84,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,218,28,36,4,136,28,51,35,71,30,2,34,1,5,99,36,4,131,28,51,4,220,27,36,4,58,4,221,29,36,4,134,5,16,4,64,28,4,70,28,29,30,3,34,1,7,135,4,220,28,36,4,136,28,51,35,72,30,2,34,1,5,92,4,126,28,36,4,128,28,51,4,71,30,2,6,103,5,103,36,4,131,28,51,4,222,27,36,4,58,4,23,29,36,4,134,5,16,4,71,28,4,23,28,29,30,3,6,104,5,104,36,4,176,28,51,4,223,27,36,4,134,5,16,4,71,28,4,26,28,29,36,4,120,4,224,29,36,4,212,35,73,29,30,3,34,1,5,104,36,4,136,28,51,35,74,30,2,34,1,5,103,36,4,131,28,51,4,225,27,36,4,58,4,35,29,36,4,134,5,16,4,71,28,4,35,28,29,30,3,34,1,7,135,4,225,28,36,4,136,28,51,35,75,30,2,34,1,5,103,36,4,131,28,51,4,226,27,36,4,58,4,227,29,36,4,134,5,16,4,71,28,4,72,28,29,30,3,34,1,7,135,4,226,28,36,4,136,28,51,35,76,30,2,34,1,5,103,36,4,137,28,51,4,228,27,36,4,58,4,31,29,36,4,134,5,16,4,71,28,4,31,28,29,36,4,140,4,73,29,36,4,141,4,86,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,228,28,36,4,136,28,51,35,77,30,2,34,1,5,103,36,4,137,28,51,4,229,27,36,4,58,4,65,29,36,4,134,7,194,4,195,28,5,16,4,71,28,4,65,28,4,84,11,30,1,29,36,4,140,4,30,29,36,4,141,4,84,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,229,28,36,4,136,28,51,35,78,30,2,34,1,5,103,36,4,169,28,51,4,230,27,36,4,171,27,36,4,73,4,75,29,36,4,32,4,122,29,36,4,200,4,231,29,29,36,4,134,4,73,29,36,4,172,3,29,36,4,58,4,74,29,30,3,34,1,7,144,4,230,28,36,4,136,28,51,35,79,30,2,34,1,5,92,4,76,28,36,4,128,28,51,4,76,30,2,6,105,5,105,36,4,131,28,51,4,232,27,36,4,58,4,23,29,36,4,134,5,16,4,76,28,4,23,28,29,30,3,6,106,5,106,36,4,136,28,51,35,80,30,2,34,1,35,81,6,107,5,105,36,4,169,28,51,4,233,27,36,4,171,5,107,30,0,29,36,4,134,27,29,36,4,172,2,29,36,4,58,4,234,29,30,3,34,1,7,144,4,233,28,36,4,136,28,51,35,82,30,2,34,1,5,105,36,4,169,28,51,4,235,27,36,4,171,5,107,30,0,29,36,4,134,27,29,36,4,172,2,29,36,4,58,4,236,29,30,3,34,1,7,144,4,235,28,36,4,136,28,51,35,83,30,2,34,1,5,105,36,4,174,28,51,4,237,30,2,36,4,238,28,51,4,239,27,36,4,134,5,16,4,76,28,4,77,28,29,36,4,240,3,29,36,4,58,4,241,29,36,4,242,4,243,29,36,4,244,35,84,29,30,3,34,1,5,105,36,4,169,28,51,4,245,27,36,4,171,27,36,4,73,4,80,29,36,4,32,4,246,29,36,4,200,4,247,29,36,4,201,4,118,29,29,36,4,134,4,73,29,36,4,172,3,29,36,4,58,4,79,29,30,3,34,1,7,144,4,245,28,36,4,136,28,51,35,85,30,2,34,1,5,105,36,4,131,28,51,4,248,27,36,4,58,4,249,29,36,4,134,5,16,4,76,28,4,90,28,29,30,3,34,1,7,135,4,248,28,36,4,136,28,51,35,86,30,2,34,1,5,105,36,4,131,28,51,4,250,27,36,4,58,4,251,29,36,4,134,5,16,4,76,28,4,89,28,29,30,3,34,1,7,135,4,250,28,36,4,136,28,51,35,87,30,2,34,1,5,105,36,4,131,28,51,4,252,27,36,4,58,4,180,29,36,4,134,5,16,4,76,28,4,33,28,29,30,3,34,1,7,135,4,252,28,36,4,136,28,51,35,88,30,2,34,1,5,105,36,4,131,28,51,4,253,27,36,4,58,4,182,29,36,4,134,5,16,4,76,28,4,21,28,29,30,3,34,1,7,135,4,253,28,36,4,136,28,51,35,89,30,2,34,1,5,105,36,4,131,28,51,4,254,27,36,4,58,4,255,29,36,4,134,5,16,4,76,28,4,91,28,29,30,3,34,1,7,135,4,254,28,36,4,136,28,51,35,90,30,2,34,1,5,105,36,4,137,28,51,4,256,27,36,4,58,4,257,29,36,4,134,5,16,4,76,28,4,92,28,29,36,4,140,4,30,29,36,4,141,4,84,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,256,28,36,4,136,28,51,35,91,30,2,34,1,5,92,4,76,28,36,4,128,28,51,4,98,30,2,6,108,5,108,36,4,131,28,51,4,258,27,36,4,58,4,98,29,36,4,134,5,16,4,76,28,4,98,28,29,30,3,34,1,7,135,4,258,28,36,4,136,28,51,35,92,30,2,34,1,5,108,36,4,137,28,51,4,259,27,36,4,58,4,260,29,36,4,134,5,16,4,76,28,4,99,28,29,36,4,140,4,30,29,36,4,141,4,261,29,36,4,142,4,200,29,36,4,143,3,29,30,3,34,1,7,144,4,259,28,36,4,136,28,51,35,93,30,2,34,1,5,92,4,76,28,36,4,129,28,51,4,105,30,2,6,109,5,109,36,4,137,28,51,4,262,27,36,4,58,4,263,29,36,4,134,5,16,4,76,28,4,83,28,29,36,4,140,4,30,29,36,4,141,4,264,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,262,28,36,4,136,28,51,35,94,30,2,34,1,5,109,36,4,137,28,51,4,265,27,36,4,58,4,266,29,36,4,134,5,16,4,76,28,4,81,28,29,36,4,140,4,73,29,36,4,141,4,267,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,265,28,36,4,136,28,51,35,95,30,2,34,1,5,109,36,4,137,28,51,4,268,27,36,4,58,4,85,29,36,4,134,5,16,4,76,28,4,85,28,29,36,4,140,4,73,29,36,4,141,4,84,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,268,28,36,4,136,28,51,35,96,30,2,34,1,5,109,36,4,137,28,51,4,269,27,36,4,58,4,270,29,36,4,134,5,16,4,76,28,4,87,28,29,36,4,140,4,30,29,36,4,141,4,271,29,36,4,142,4,200,29,36,4,143,3,29,30,3,34,1,7,144,4,269,28,36,4,136,28,51,35,97,30,2,34,1,5,109,36,4,174,28,51,4,272,30,2,36,4,176,28,51,4,273,27,36,4,134,5,16,4,76,28,4,93,28,29,36,4,120,4,272,29,30,3,34,1,7,144,4,273,28,36,4,136,28,51,35,98,30,2,34,1,5,109,36,4,174,28,51,4,274,30,2,36,4,176,28,51,4,275,27,36,4,134,5,16,4,76,28,4,94,28,29,36,4,120,4,274,29,30,3,34,1,7,144,4,275,28,36,4,136,28,51,35,99,30,2,34,1,5,109,36,4,131,28,51,4,276,27,36,4,58,4,277,29,36,4,134,5,16,4,76,28,4,95,28,29,30,3,34,1,7,135,4,276,28,36,4,136,28,51,35,100,30,2,34,1,5,92,4,126,28,36,4,128,28,51,4,40,30,2,6,110,5,110,36,4,131,28,51,4,278,27,36,4,58,4,279,29,36,4,134,5,16,4,40,28,4,41,28,29,30,3,6,111,5,111,36,4,176,28,51,4,280,27,36,4,134,5,16,4,40,28,4,46,28,29,36,4,120,4,281,29,30,3,34,1,7,135,4,278,28,36,4,136,28,51,35,101,30,2,34,1,5,110,36,4,131,28,51,4,282,27,36,4,58,4,283,29,36,4,134,5,16,4,40,28,4,42,28,29,30,3,34,1,7,135,4,282,28,36,4,136,28,51,35,102,30,2,34,1,5,110,36,4,131,28,51,4,284,27,36,4,58,4,285,29,36,4,134,5,16,4,40,28,4,43,28,29,30,3,6,112,5,112,36,4,176,28,51,4,286,27,36,4,134,5,16,4,40,28,4,47,28,29,36,4,120,4,287,29,30,3,34,1,7,135,4,284,28,36,4,136,28,51,35,103,30,2,34,1,7,144,4,286,28,36,4,136,28,51,35,104,30,2,34,1,7,144,4,280,28,36,4,136,28,51,35,105,30,2,34,1,5,110,36,4,131,28,51,4,288,27,36,4,58,4,289,29,36,4,134,5,16,4,40,28,4,44,28,29,30,3,6,113,5,113,36,4,176,28,51,4,290,27,36,4,134,5,16,4,40,28,4,48,28,29,36,4,120,4,196,29,30,3,34,1,7,135,4,288,28,36,4,136,28,51,35,106,30,2,34,1,7,144,4,290,28,36,4,136,28,51,35,107,30,2,34,1,5,110,36,4,131,28,51,4,291,27,36,4,58,4,292,29,36,4,134,5,16,4,40,28,4,45,28,29,30,3,34,1,7,135,4,291,28,36,4,136,28,51,35,108,30,2,34,1,5,110,36,4,137,28,51,4,293,27,36,4,58,4,294,29,36,4,134,5,16,4,40,28,4,49,28,29,36,4,140,4,295,29,36,4,141,4,296,29,36,4,142,4,30,29,36,4,143,3,29,30,3,34,1,7,144,4,293,28,36,4,136,28,51,35,109,30,2,34,1,5,110,36,4,169,28,51,4,297,27,36,4,171,27,36,4,73,4,52,29,36,4,32,4,298,29,36,4,200,4,299,29,36,4,201,4,300,29,29,36,4,134,4,73,29,36,4,172,3,29,36,4,58,4,51,29,30,3,34,1,7,144,4,297,28,36,4,136,28,51,35,110,30,2,34,1,5,110,36,4,131,28,51,4,301,27,36,4,58,4,302,29,36,4,134,5,16,4,53,28,4,23,28,29,30,3,6,114,5,114,36,4,176,28,51,4,303,27,36,4,134,5,16,4,53,28,4,54,28,29,36,4,120,4,304,29,30,3,34,1,5,114,36,4,176,28,51,4,305,27,36,4,134,5,16,4,53,28,4,55,28,29,36,4,120,4,306,29,30,3,34,1,7,135,4,301,28,36,4,136,28,51,35,111,30,2,34,1,7,144,4,303,28,36,4,136,28,51,35,112,30,2,34,1,7,144,4,305,28,36,4,136,28,51,35,113,30,2,34,1,5,92,4,127,28,36,4,128,28,51,4,307,30,2,6,115,5,115,36,4,308,28,51,4,309,35,114,30,3,34,1,5,115,36,4,174,28,51,4,310,30,2,36,4,238,28,51,4,311,27,36,4,134,4,312,29,36,4,240,2,29,36,4,58,4,313,29,30,3,34,1,5,1,4,314,7,144,4,311,28,29,5,115,36,4,131,28,51,4,315,27,36,4,58,4,315,29,36,4,134,2,29,30,3,34,1,7,135,4,315,28,36,4,136,28,51,35,115,30,2,34,1,5,115,36,4,174,28,51,4,316,30,2,36,4,238,28,51,4,317,27,36,4,134,4,318,29,36,4,240,3,29,36,4,58,4,319,29,36,4,242,4,320,29,30,3,34,1,5,92,4,127,28,36,4,129,28,51,4,321,30,2,6,116,5,2,36,4,322,28,51,5,1,30,2,34,1,5,3,36,4,322,28,51,5,1,30,2,34,1,5,3,36,4,323,28,51,30,1,34,1,5,3,36,4,324,28,51,27,36,4,73,4,311,29,30,2,34,1,5,2,36,4,325,28,51,4,121,30,2,34,1,5,3,36,4,325,28,51,4,326,5,15,15,30,2,34,1,5,3,36,4,327,28,51,5,92,4,127,28,30,2,34,1,5,2,36,4,328,28,51,5,92,4,127,28,30,2,34,1,5,1,36,4,329,28,51,2,30,2,34,1,4,30,6,117,4,30,6,118,7,330,4,331,28,30,0,6,119,5,1,36,4,332,28,51,4,333,30,2,34,1,5,10,4,334,28,36,4,335,28,51,35,116,30,2,34,1,5,10,4,336,28,36,4,335,28,51,35,117,30,2,34,1,5,1,36,4,337,28,51,35,118,30,2,34,1,5,3,36,4,338,28,51,30,1,34,1,31,0}
local ___l2={"https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/refs/heads/main/","loadstring","game","HttpGet","Library.lua","addons/ThemeManager.lua","addons/SaveManager.lua","https://raw.githubusercontent.com/VoltSec3/leetware/main/Modules/ESP.luau","https://raw.githubusercontent.com/VoltSec3/leetware/main/Modules/Chams.luau","https://raw.githubusercontent.com/VoltSec3/leetware/main/Modules/Tracers.luau","https://raw.githubusercontent.com/VoltSec3/leetware/main/Modules/Aimbot.luau","https://raw.githubusercontent.com/VoltSec3/leetware/main/Modules/Utils.luau","GetService","Players","RunService","Workspace","Stats","UserInputService","LocalPlayer","tostring","GameId","FriendCheck","Box","Enabled","Style","Corner","Color","Color3","fromRGB",255,0,"Thickness",2,"TeamCheck","TeamColor","Rainbow","AutoThickness","Fill","Opacity",0.15,"Information","ShowName","ShowDisplayName","ShowWeapon","ShowTeam","CustomTextColor","NameColor","WeaponColor","TeamTextColor","NameScale",14,"Font","UI","Health","BorderColor","FillColor","BoxBorder","BoxFill","Text","HealthBorder","HealthFill","DarkenBorders","DarkenAmount",50,"Chams","Transparency",0.5,"Outline","OutlineColor","OutlineTransparency","AlwaysOnTop","Tracers","ShowNotInView",1,"Origin","Bottom","Aimbot","Bind","MB2","Targeting","Normal","Range",500,"Fov",100,"Smoothing",5,"Prediction",0.065,"WallCheck","LockAim","HealthCheck","MinHealth","FovColor","TargetedFovColor","RainbowFov","RainbowSpeed",0.005,"Triggerbot","TriggerbotDelay","ExcludeTeams","PrioritizeTeams","ESP","new","Player","Settings","Utils","Shoot","URL","https://files.catbox.moe/lip2i4.mp3","File","leetware_shoot.mp3","Reload","https://files.catbox.moe/c4qtkm.mp3","leetware_reload.mp3",0.25,0.18,360,"Random","CreateWindow","Title","leetware","Center","AutoShow","Main","AddTab","Visuals","UI Settings","AddLeftGroupbox","AddRightGroupbox","Blatant","AddToggle","RainbowTools","Rainbow Tools","Default","Toggles","OnChanged","AddSlider","GunTransparency","Gun Transparency","Min","Max","Rounding","Compact","Options","CustomGunSounds","Custom Gun Sounds","Anti Aim","AntiAimEnabled","AntiAimRotationTime","Rotation Time",0.1,"AntiAimRandomization","Randomization","AntiAimPreviewTransparency","Preview Transparency","AntiAimShowPreview","Show Next Rotation","AntiAimPreviewRainbow","SNR Rainbow","DoorCollision","Door Collision","NoSpread","No Spread","InfiniteRange","Infinite Range","InfiniteAmmo","Infinite Ammo","ESPEnabled","AddDropdown","ESPBoxStyle","Values","Multi","Box Style","AddLabel","Box Color","AddColorPicker","ESPBoxColor","ESPRainbow","ESPTeamCheck","Team Check","ESPFriendCheck","Friend Check","ESPAutothickness","Auto Thickness","ESPThickness","Box Thickness",6,"ESPFillBox","Fill Box","ESPFillBoxColor","Fill Color","ESPFillOpacity","Fill Opacity","math","floor","Team Color","ESPTeamColor","Box Border","Box Fill",3,4,"Health Border","Health Fill","Apply Team Color","ESPDarkenBorders","Darken Borders","ESPDarkenAmount","Darken Amount","ESPChams","ESPChamsColor","Chams Color","Callback","ESPChamsRainbow","ESPChamsTransparency","ESPChamsOutline","ESPChamsOutlineColor","Outline Color","ESPChamsOutlineTransparency","Outline Transparency","ESPChamsAlwaysOnTop","Always On Top","ESPTracers","ESPTracerColor","Tracer Color","ESPTracersRainbow","ESPTracersShowNotInView","Show Not In View","ESPTracerThickness","ESPTracerTransparency","ESPTracerOrigin","Top","AimbotEnabled","AimbotExcludeTeams","Exclude Teams","AimbotPrioritizeTeams","Prioritize Teams","Aim Bind","AddKeyPicker","AimbotBind","NoUI","Aim bind","Mode","Hold","ChangedCallback","AimbotTargeting","Closest","Furthest","AimbotLockAim","Lock Aim","AimbotWallCheck","Wall Check","AimbotTeamCheck","AimbotFriendCheck","AimbotHealthCheck","Health Check","AimbotMinHealth","Minimum Health","AimbotTriggerbot","AimbotTriggerbotDelay","Triggerbot Delay",0.3,"AimbotFov","Aim FOV",1000,"AimbotRange","Range (Studs)",1500,"AimbotSmoothing","AimbotPrediction","Prediction Strength",0.2,"FOV Color","AimbotFovColor","Targeted FOV Color","AimbotTargetedFovColor","AimbotRainbowFov","Rainbow FOV","ESPShowName","Show Name","ESPNameColor","Name Color","ESPShowDisplayName","Show Display Name","ESPShowWeapon","Show Weapon","ESPWeaponColor","Weapon Color","ESPShowTeam","Show Team","ESPTeamTextColor","ESPCustomTextColor","Custom Text Colors","ESPNameScale","Name Scale",10,24,"ESPFont","System","Plex","Monospace","ESPShowHealth","Show Health","ESPHealthBorderColor","Health Border Color","ESPHealthFillColor","Health Fill Color","Menu","AddButton","Unload","Menu bind","MenuKeybind","End","Menu keybind","ToggleKeybind","Watermark","Config Bind","ConfigBind","F5","Config bind","Toggle","Configs","SetLibrary","IgnoreThemeSettings","SetIgnoreIndexes","SetFolder","leetware/configs/","BuildConfigSection","ApplyToTab","SetWatermarkVisibility","os","clock","SetWatermark","leetware | loading","Heartbeat","Connect","RenderStepped","OnUnload","LoadAutoloadConfig"}
local _0104={{K={"game","HttpGet","loadstring","assert","string","format","Failed to compile %s: %s","tostring","type","new","function","%s did not return a valid module"},C={7,0,36,4,1,28,51,5,0,30,2,6,2,7,2,5,2,39,1,2,6,4,6,3,46,7,3,5,3,46,7,4,4,5,28,4,6,5,1,7,7,5,4,39,1,-1,47,-1,47,1,34,1,5,3,30,0,6,5,46,7,3,5,5,36,33,80,34,1,7,8,5,5,4,9,28,30,1,4,10,16,7,4,4,5,28,4,11,5,1,39,2,-1,47,1,34,1,5,5,31,1},P={},U=nil,nParams=2},{K={"pairs","pcall","Notify","Failed to load custom ","string","lower"," sound",3},C={37,0,33,9,2,31,1,32,9,27,6,0,7,0,37,1,39,1,3,6,3,6,2,6,1,56,1,2,3,49,4,49,5,5,1,5,2,5,3,39,2,2,6,5,6,4,5,4,6,3,5,4,1,17,33,118,7,1,35,1,39,1,2,6,7,6,6,5,6,24,33,105,37,2,36,4,2,28,51,4,3,7,4,4,5,28,5,4,30,1,4,6,15,15,4,7,30,3,34,1,3,31,1,32,105,5,0,5,4,5,7,29,49,6,49,7,32,29,5,0,38,0,2,31,1},P={{K={"isfile","File","writefile","game","HttpGet","URL","getcustomasset"},C={7,0,37,0,4,1,28,30,1,24,33,41,46,7,2,37,0,4,1,28,7,3,36,4,4,28,51,37,0,4,5,28,39,2,-1,47,1,34,1,32,41,7,6,37,0,4,1,28,39,1,-1,31,-1},P={},U={{1,5}},nParams=0}},U={{1,34},{1,35},{1,1}},nParams=0},{K={"Sounds","Attributes","Captured","SoundId","GetAttribute"},C={37,0,5,0,37,0,5,0,28,36,24,33,31,34,1,27,36,4,0,27,29,36,4,1,27,29,36,4,2,27,29,29,37,0,5,0,28,4,2,28,5,2,28,24,33,98,37,0,5,0,28,4,0,28,5,2,5,1,4,3,28,29,37,0,5,0,28,4,1,28,5,2,5,0,36,4,4,28,51,5,2,30,2,29,37,0,5,0,28,4,2,28,5,2,2,29,32,98,31,0},P={},U={{1,33}},nParams=3},{K={"IsA","Tool","FindFirstChild","Handle","Shoot","Object","ShootSound","Id","Reload","ReloadSound","pairs","Sound","SoundId","SetAttribute"},C={37,0,24,36,24,33,21,34,1,5,0,36,4,0,28,51,4,1,30,2,24,33,27,31,0,32,27,5,0,36,4,2,28,51,4,3,30,2,6,1,5,1,24,33,49,31,0,32,49,27,36,4,4,27,36,4,5,5,1,36,4,2,28,51,4,6,30,2,29,36,4,7,37,0,4,4,28,29,29,36,4,8,27,36,4,5,5,1,36,4,2,28,51,4,9,30,2,29,36,4,7,37,0,4,8,28,29,29,6,2,7,10,5,2,39,1,3,6,5,6,4,6,3,56,3,4,5,49,6,49,7,5,3,5,4,5,5,39,2,2,6,7,6,6,5,6,6,5,5,6,1,17,33,233,5,7,4,5,28,36,33,178,34,1,5,7,4,5,28,36,4,0,28,51,4,11,30,2,33,231,37,1,5,0,5,7,4,5,28,5,6,30,3,34,1,5,7,4,5,28,4,12,5,7,4,7,28,29,5,0,36,4,13,28,51,5,6,4,12,15,5,7,4,7,28,30,3,34,1,32,231,32,127,31,0},P={},U={{1,34},{1,37}},nParams=1},{K={"pairs","Parent","Sounds","FindFirstChild","Handle","Sound","IsA","SoundId","Attributes","SetAttribute","table","clear"},C={7,0,37,0,39,1,3,6,2,6,1,6,0,56,0,1,2,49,3,49,4,5,0,5,1,5,2,39,2,2,6,4,6,3,5,3,6,2,5,3,1,17,33,268,5,3,36,33,56,34,1,5,3,4,1,28,33,242,7,0,5,4,4,2,28,39,1,3,6,7,6,6,6,5,56,5,6,7,49,8,49,9,5,5,5,6,5,7,39,2,2,6,9,6,8,5,8,6,7,5,8,1,17,33,176,5,3,36,4,3,28,51,4,4,30,2,6,10,5,10,36,33,139,34,1,5,10,36,4,3,28,51,5,8,4,5,15,30,2,6,11,5,11,36,33,159,34,1,5,11,36,4,6,28,51,4,5,30,2,33,170,5,11,4,7,5,9,29,32,170,49,10,49,11,32,78,7,0,5,4,4,8,28,39,1,3,6,14,6,13,6,12,56,12,13,14,49,15,49,16,5,12,5,13,5,14,39,2,2,6,16,6,15,5,15,6,14,5,15,1,17,33,240,5,3,36,4,9,28,51,5,15,5,16,30,3,34,1,32,196,32,242,49,5,49,6,49,7,49,8,49,9,49,10,49,11,49,12,49,13,49,14,49,15,49,16,32,17,7,10,4,11,28,37,0,30,1,34,1,31,0},P={},U={{1,33}},nParams=0},{K={"math","rad","NextInteger",0,"floor"},C={46,7,0,4,1,28,46,37,0,36,4,2,28,51,4,3,7,0,4,4,28,37,1,39,1,-1,47,-1,47,-1,31,-1},P={},U={{1,58},{1,47}},nParams=0},{K={"Destroy"},C={37,0,33,20,37,0,36,4,0,28,51,30,1,34,1,1,38,0,32,20,31,0},P={},U={{1,54}},nParams=0},{K={"os","clock","FindFirstChildOfClass","Humanoid","AutoRotate"},C={5,0,38,0,37,1,39,0,1,38,2,37,1,39,0,1,38,3,7,0,4,1,28,30,0,37,4,9,38,5,5,0,36,4,2,28,51,4,3,30,2,6,1,5,1,33,62,5,1,4,4,28,38,6,5,1,4,4,3,29,32,62,31,0},P={},U={{1,52},{1,59},{1,49},{1,50},{1,46},{1,51},{1,53}},nParams=1},{K={"Archivable","pcall","ipairs","GetDescendants","IsA","Script","LocalScript","ModuleScript","Humanoid","Destroy","BasePart","Anchored","CanCollide","CanTouch","CanQuery","Transparency",0.5,"Color","Color3","fromRGB",150,"Decal","Texture","Name","LeetwareAntiAimPreview","Parent"},C={37,0,30,0,34,1,5,0,4,0,28,6,1,5,0,4,0,2,29,7,1,35,1,39,1,2,6,3,6,2,5,0,4,0,5,1,29,5,2,24,36,24,33,49,34,1,5,3,24,33,55,31,0,32,55,46,7,2,5,3,36,4,3,28,51,39,1,-1,47,3,6,6,6,5,6,4,56,4,5,6,49,7,49,8,5,4,5,5,5,6,39,2,2,6,8,6,7,5,7,6,6,5,7,1,17,33,289,5,8,36,4,4,28,51,4,5,30,2,36,24,33,135,34,1,5,8,36,4,4,28,51,4,6,30,2,36,24,33,152,34,1,5,8,36,4,4,28,51,4,7,30,2,36,24,33,169,34,1,5,8,36,4,4,28,51,4,8,30,2,33,184,5,8,36,4,9,28,51,30,1,34,1,32,287,5,8,36,4,4,28,51,4,10,30,2,33,248,5,8,4,11,2,29,5,8,4,12,3,29,5,8,4,13,3,29,5,8,4,14,3,29,5,8,4,15,4,16,29,5,8,4,17,7,18,4,19,28,4,20,4,20,4,20,30,3,29,32,287,5,8,36,4,4,28,51,4,21,30,2,36,24,33,276,34,1,5,8,36,4,4,28,51,4,22,30,2,33,287,5,8,4,15,4,16,29,32,287,32,80,5,3,4,23,4,24,29,5,3,4,25,37,1,29,5,3,38,2,31,0},P={{K={"Clone"},C={37,0,36,4,0,28,51,39,1,-1,31,-1},P={},U={{1,0}},nParams=0}},U={{1,60},{1,11},{1,54}},nParams=1},{K={"Parent","FindFirstChild","HumanoidRootPart","CFrame","new","Position","Angles",0,"Inverse","PivotTo","GetPivot",0.01,1,"Color3","fromHSV","fromRGB",150,"ipairs","GetDescendants","IsA","BasePart","Color","Transparency","Decal","Texture"},C={37,0,24,36,24,33,15,34,1,37,0,4,0,28,24,33,27,37,1,5,0,30,1,34,1,32,27,37,0,24,33,36,31,0,32,36,5,0,36,4,1,28,51,4,2,30,2,6,2,37,0,36,4,1,28,51,4,2,30,2,6,3,5,2,36,33,71,34,1,5,3,33,143,7,3,4,4,28,5,2,4,5,28,30,1,7,3,4,6,28,4,7,5,1,4,7,30,3,11,6,4,5,4,5,3,4,3,28,36,4,8,28,51,30,1,11,6,5,37,0,36,4,9,28,51,5,5,37,0,36,4,10,28,51,30,1,11,30,2,34,1,32,143,37,2,4,11,9,4,12,13,38,2,37,3,36,33,173,34,1,7,13,4,14,28,37,2,4,12,4,12,30,3,36,24,33,192,34,1,7,13,4,15,28,4,16,4,16,4,16,30,3,6,6,46,7,17,37,0,36,4,18,28,51,39,1,-1,47,3,6,9,6,8,6,7,56,7,8,9,49,10,49,11,5,7,5,8,5,9,39,2,2,6,11,6,10,5,10,6,9,5,10,1,17,33,316,5,11,36,4,19,28,51,4,20,30,2,33,275,5,11,4,21,5,6,29,5,11,4,22,37,4,29,32,314,5,11,36,4,19,28,51,4,23,30,2,36,24,33,303,34,1,5,11,36,4,19,28,51,4,24,30,2,33,314,5,11,4,22,37,4,29,32,314,32,219,31,0},P={},U={{1,54},{1,62},{1,57},{1,56},{1,48}},nParams=2},{K={"Sit","GetState","Enum","HumanoidStateType","Seated","OverlapParams","new","FilterType","RaycastFilterType","Include","FilterDescendantsInstances",1,"ipairs","GetPartBoundsInRadius","Position","IsA","TrussPart"},C={5,2,4,0,28,36,24,33,29,34,1,5,2,36,4,1,28,51,30,1,7,2,4,3,28,4,4,28,16,33,36,2,31,1,32,36,7,5,4,6,28,30,0,6,3,5,3,4,7,7,2,4,8,28,4,9,28,29,5,3,4,10,27,36,4,11,37,0,29,29,46,7,12,37,0,36,4,13,28,51,5,1,4,14,28,4,11,5,3,39,4,-1,47,3,6,6,6,5,6,4,56,4,5,6,49,7,49,8,5,4,5,5,5,6,39,2,2,6,8,6,7,5,7,6,6,5,7,1,17,33,151,5,8,36,4,15,28,51,4,16,30,2,33,149,2,31,1,32,149,32,104,3,31,1},P={},U={{1,11}},nParams=3},{K={"Parent","FindFirstChildOfClass","Humanoid","AutoRotate"},C={37,0,36,33,12,34,1,37,0,4,0,28,33,42,37,0,36,4,1,28,51,4,2,30,2,6,0,5,0,33,40,5,0,4,3,37,1,29,32,40,32,42,1,38,0,1,38,1,31,0},P={},U={{1,52},{1,53}},nParams=0},{K={"Character"},C={5,0,38,0,5,0,24,33,23,37,1,30,0,34,1,37,2,30,0,34,1,32,43,37,3,4,0,28,33,43,37,4,37,3,4,0,28,30,1,34,1,32,43,31,0},P={},U={{1,45},{1,65},{1,60},{1,14},{1,61}},nParams=1},{K={"Character","FindFirstChildOfClass","Humanoid","FindFirstChild","HumanoidRootPart","AutoRotate","os","clock","Position","CFrame","new","Angles",0},C={37,0,24,33,9,31,0,32,9,37,1,4,0,28,6,0,5,0,24,33,25,31,0,32,25,37,2,5,0,17,33,42,37,3,5,0,30,1,34,1,32,42,5,0,36,4,1,28,51,4,2,30,2,6,1,5,0,36,4,3,28,51,4,4,30,2,6,2,5,1,24,36,24,33,80,34,1,5,2,24,33,86,31,0,32,86,37,4,5,0,5,2,5,1,30,3,33,132,5,1,4,5,37,5,29,37,6,36,33,114,34,1,37,7,33,128,37,8,5,0,37,9,30,2,34,1,32,128,31,0,32,132,5,1,4,5,3,29,7,6,4,7,28,30,0,37,10,21,33,175,37,9,38,11,37,12,39,0,1,38,9,7,6,4,7,28,30,0,37,13,9,38,10,32,175,5,2,4,8,28,6,3,5,2,4,9,7,9,4,10,28,5,3,30,1,7,9,4,11,28,4,12,37,11,4,12,30,3,11,29,37,6,33,226,37,8,5,0,37,9,30,2,34,1,32,232,37,14,30,0,34,1,31,0},P={},U={{1,45},{1,14},{1,52},{1,61},{1,64},{1,53},{1,55},{1,54},{1,63},{1,50},{1,51},{1,49},{1,59},{1,46},{1,60}},nParams=0},{K={"FindFirstChildOfClass","Backpack","Character","ipairs","GetChildren","IsA","Tool","table","insert"},C={27,6,0,37,0,36,4,0,28,51,4,1,30,2,6,1,37,0,4,2,28,6,2,5,1,33,111,46,7,3,5,1,36,4,4,28,51,39,1,-1,47,3,6,5,6,4,6,3,56,3,4,5,49,6,49,7,5,3,5,4,5,5,39,2,2,6,7,6,6,5,6,6,5,5,6,1,17,33,109,5,7,36,4,5,28,51,4,6,30,2,33,107,7,7,4,8,28,5,0,5,7,30,2,34,1,32,107,32,52,32,111,5,2,33,199,46,7,3,5,2,36,4,4,28,51,39,1,-1,47,3,6,10,6,9,6,8,56,8,9,10,49,11,49,12,5,8,5,9,5,10,39,2,2,6,12,6,11,5,11,6,10,5,11,1,17,33,197,5,12,36,4,5,28,51,4,6,30,2,33,195,7,7,4,8,28,5,0,5,12,30,2,34,1,32,195,32,140,32,199,5,0,31,1},P={},U={{1,14}},nParams=0},{K={"GetAttribute","FindFirstChild","IsA","ValueBase","Value"},C={5,0,36,4,0,28,51,5,1,30,2,6,2,5,0,36,4,1,28,51,5,1,30,2,6,3,5,2,1,16,36,33,37,34,1,5,3,36,33,53,34,1,5,3,36,4,2,28,51,4,3,30,2,33,64,5,3,4,4,28,6,2,32,64,5,2,31,1},P={},U=nil,nParams=2},{K={"SetAttribute","FindFirstChild","IsA","ValueBase","Value"},C={5,0,36,4,0,28,51,5,1,5,2,30,3,34,1,5,0,36,4,1,28,51,5,1,30,2,6,3,5,3,36,33,46,34,1,5,3,36,4,2,28,51,4,3,30,2,33,57,5,3,4,4,5,2,29,32,57,31,0},P={},U=nil,nParams=3},{K={"Attribute","GetAttribute","Value","Child","FindFirstChild"},C={37,0,5,0,37,0,5,0,28,36,24,33,16,34,1,27,29,37,0,5,0,28,5,1,28,1,16,33,82,37,0,5,0,28,5,1,27,36,4,0,5,0,36,4,1,28,51,5,1,30,2,29,36,4,2,37,1,5,0,5,1,30,2,29,36,4,3,5,0,36,4,4,28,51,5,1,30,2,29,29,32,82,31,0},P={},U={{1,44},{1,69}},nParams=2},{K={"Parent","Attribute","SetAttribute","FindFirstChild","IsA","ValueBase","Value"},C={37,0,5,0,28,36,33,18,34,1,37,0,5,0,28,5,1,28,6,2,5,2,24,36,24,33,35,34,1,5,0,4,0,28,24,33,41,31,0,32,41,5,2,4,1,28,1,16,33,66,5,0,36,4,2,28,51,5,1,1,30,3,34,1,32,84,5,0,36,4,2,28,51,5,1,5,2,4,1,28,30,3,34,1,5,0,36,4,3,28,51,5,1,30,2,6,3,5,3,36,33,115,34,1,5,3,36,4,4,28,51,4,5,30,2,36,33,127,34,1,5,2,4,6,28,1,17,33,141,5,3,4,6,5,2,4,6,28,29,32,141,31,0},P={},U={{1,44}},nParams=2},{K={"ipairs"},C={46,7,0,37,0,39,0,-1,47,3,6,5,6,4,6,3,56,3,4,5,49,6,49,7,5,3,5,4,5,5,39,2,2,6,7,6,6,5,6,6,5,5,6,1,17,33,141,7,0,5,1,39,1,3,6,10,6,9,6,8,56,8,9,10,49,6,49,11,5,8,5,9,5,10,39,2,2,6,11,6,6,5,6,6,10,5,6,1,17,33,131,5,0,33,119,37,1,5,7,5,11,30,2,34,1,37,2,5,7,5,11,5,2,30,3,34,1,32,129,37,3,5,7,5,11,30,2,34,1,32,64,49,8,49,9,49,10,49,11,32,20,31,0},P={},U={{1,68},{1,71},{1,70},{1,72}},nParams=3},{K={"pairs","Parent","table","clear"},C={7,0,37,0,39,1,3,6,2,6,1,6,0,56,0,1,2,49,3,49,4,5,0,5,1,5,2,39,2,2,6,4,6,3,5,3,6,2,5,3,1,17,33,122,5,3,36,33,56,34,1,5,3,4,1,28,33,112,7,0,5,4,39,1,3,6,7,6,6,6,5,56,5,6,7,49,8,5,5,5,6,5,7,39,2,1,6,8,5,8,6,7,5,8,1,17,33,110,37,1,5,3,5,8,30,2,34,1,32,75,32,112,49,5,49,6,49,7,49,8,32,17,7,2,4,3,28,37,0,30,1,34,1,31,0},P={},U={{1,44},{1,72}},nParams=0},{K={"ipairs","Toggles","NoSpread","Value","SpreadRadius",0,"InfiniteRange","Range",100000,"InfiniteAmmo","tonumber","MaxAmmo","CurrentAmmo","Local_CurrentAmmo"},C={46,7,0,37,0,39,0,-1,47,3,6,2,6,1,6,0,56,0,1,2,49,3,49,4,5,0,5,1,5,2,39,2,2,6,4,6,3,5,3,6,2,5,3,1,17,33,227,7,1,4,2,28,36,33,65,34,1,7,1,4,2,28,4,3,28,33,91,37,1,5,4,4,4,30,2,34,1,37,2,5,4,4,4,4,5,30,3,34,1,32,91,7,1,4,6,28,36,33,109,34,1,7,1,4,6,28,4,3,28,33,135,37,1,5,4,4,7,30,2,34,1,37,2,5,4,4,7,4,8,30,3,34,1,32,135,7,1,4,9,28,36,33,153,34,1,7,1,4,9,28,4,3,28,33,223,46,7,10,37,3,5,4,4,11,39,2,-1,47,1,6,5,5,5,33,221,37,1,5,4,4,12,30,2,34,1,37,1,5,4,4,13,30,2,34,1,37,2,5,4,4,12,5,5,30,3,34,1,37,2,5,4,4,13,5,5,30,3,34,1,32,221,32,223,49,5,32,20,31,0},P={},U={{1,68},{1,71},{1,70},{1,69}},nParams=0},{K={"Color3","fromHSV",1},C={7,0,4,1,28,37,0,5,0,9,4,2,13,4,2,4,2,39,3,-1,31,-1},P={},U={{1,28}},nParams=1},{K={"Instance","CFrame","Color","BrickColor","TextureID","TextureContent","Texture","VertexColor","IsA","BasePart","MeshPart","pcall","SpecialMesh","FileMesh","TextureId","Decal"},C={37,0,5,0,28,33,11,31,0,32,11,27,36,4,0,5,0,29,36,4,1,1,29,36,4,2,1,29,36,4,3,1,29,36,4,4,1,29,36,4,5,1,29,36,4,6,1,29,36,4,7,1,29,6,1,5,0,36,4,8,28,51,4,9,30,2,33,100,5,1,4,1,5,0,4,1,28,29,5,1,4,2,5,0,4,2,28,29,5,1,4,3,5,0,4,3,28,29,32,100,5,0,36,4,8,28,51,4,10,30,2,33,133,5,1,4,4,5,0,4,4,28,29,7,11,35,1,30,1,34,1,32,227,5,0,36,4,8,28,51,4,12,30,2,36,24,33,161,34,1,5,0,36,4,8,28,51,4,13,30,2,33,185,5,1,4,4,5,0,4,14,28,29,5,1,4,7,5,0,4,7,28,29,32,227,5,0,36,4,8,28,51,4,6,30,2,36,24,33,213,34,1,5,0,36,4,8,28,51,4,15,30,2,33,227,5,1,4,6,5,0,4,6,28,29,32,227,37,0,5,0,5,1,29,31,0},P={{K={"TextureContent"},C={37,0,4,0,37,1,4,0,28,29,31,0},P={},U={{1,1},{1,0}},nParams=0}},U={{1,29}},nParams=1},{K={"IsA","BasePart","Color","BrickColor","new","MeshPart","TextureID","","pcall","SpecialMesh","FileMesh","TextureId","VertexColor","Vector3",1,"Texture","Decal"},C={5,0,36,4,0,28,51,4,1,30,2,33,52,37,0,5,0,30,1,34,1,37,1,5,1,30,1,6,2,5,0,4,2,5,2,29,5,0,4,3,7,3,4,4,28,5,2,30,1,29,32,52,5,0,36,4,0,28,51,4,5,30,2,33,119,37,0,5,0,30,1,34,1,5,0,4,6,4,7,29,7,8,35,1,30,1,34,1,37,1,5,1,30,1,6,3,5,0,4,2,5,3,29,5,0,4,3,7,3,4,4,28,5,3,30,1,29,32,231,5,0,36,4,0,28,51,4,9,30,2,36,24,33,147,34,1,5,0,36,4,0,28,51,4,10,30,2,33,184,37,0,5,0,30,1,34,1,5,0,4,11,4,7,29,5,0,4,12,7,13,4,4,28,4,14,4,14,4,14,30,3,29,32,231,5,0,36,4,0,28,51,4,15,30,2,36,24,33,212,34,1,5,0,36,4,0,28,51,4,16,30,2,33,231,37,0,5,0,30,1,34,1,5,0,4,15,4,7,29,32,231,31,0},P={{K={"TextureContent","Content","none"},C={37,0,4,0,7,1,4,2,28,29,31,0},P={},U={{1,0}},nParams=0}},U={{1,77},{1,76}},nParams=2},{K={"IsA","Tool","GetDescendants","math","max",1,"ipairs"},C={5,0,36,4,0,28,51,4,1,30,2,24,33,18,31,0,32,18,5,0,36,4,2,28,51,30,1,6,1,7,3,4,4,28,5,1,26,4,5,30,2,6,2,7,6,5,1,39,1,3,6,5,6,4,6,3,56,3,4,5,49,6,49,7,5,3,5,4,5,5,39,2,2,6,7,6,6,5,6,6,5,5,6,1,17,33,102,37,0,5,7,5,6,5,2,12,30,2,34,1,32,60,31,0},P={},U={{1,78}},nParams=1},{K={"ipairs","GetChildren","IsA","Tool"},C={46,7,0,5,0,36,4,1,28,51,39,1,-1,47,3,6,3,6,2,6,1,56,1,2,3,49,4,49,5,5,1,5,2,5,3,39,2,2,6,5,6,4,5,4,6,3,5,4,1,17,33,77,5,5,36,4,2,28,51,4,3,30,2,33,75,37,0,5,5,30,1,34,1,32,75,32,25,31,0},P={},U={{1,79}},nParams=1},{K={"Transparency"},C={37,0,5,0,28,1,17,33,13,31,0,32,13,37,0,5,0,5,0,4,0,28,29,31,0},P={},U={{1,31}},nParams=1},{K={"IsA","Tool","ipairs","GetDescendants","BasePart","Transparency"},C={5,0,36,4,0,28,51,4,1,30,2,24,33,18,31,0,32,18,46,7,2,5,0,36,4,3,28,51,39,1,-1,47,3,6,3,6,2,6,1,56,1,2,3,49,4,49,5,5,1,5,2,5,3,39,2,2,6,5,6,4,5,4,6,3,5,4,1,17,33,102,5,5,36,4,0,28,51,4,4,30,2,33,100,37,0,5,5,30,1,34,1,5,5,4,5,37,1,29,32,100,32,43,31,0},P={},U={{1,81},{1,30}},nParams=1},{K={"ipairs","GetChildren","IsA","Tool"},C={46,7,0,5,0,36,4,1,28,51,39,1,-1,47,3,6,3,6,2,6,1,56,1,2,3,49,4,49,5,5,1,5,2,5,3,39,2,2,6,5,6,4,5,4,6,3,5,4,1,17,33,77,5,5,36,4,2,28,51,4,3,30,2,33,75,37,0,5,5,30,1,34,1,32,75,32,25,31,0},P={},U={{1,82}},nParams=1},{K={"pairs","Parent","Transparency","table","clear"},C={7,0,37,0,39,1,3,6,2,6,1,6,0,56,0,1,2,49,3,49,4,5,0,5,1,5,2,39,2,2,6,4,6,3,5,3,6,2,5,3,1,17,33,69,5,3,36,33,56,34,1,5,3,4,1,28,33,67,5,3,4,2,5,4,29,32,67,32,17,7,3,4,4,28,37,0,30,1,34,1,31,0},P={},U={{1,31}},nParams=0},{K={"pairs","Parent","CFrame","Color","BrickColor","IsA","MeshPart","pcall","SpecialMesh","FileMesh","TextureId","TextureID","","VertexColor","Texture","Decal","table","clear"},C={7,0,37,0,39,1,3,6,2,6,1,6,0,56,0,1,2,49,3,49,4,5,0,5,1,5,2,39,2,2,6,4,6,3,5,3,6,2,5,3,1,17,33,269,5,3,36,33,56,34,1,5,3,4,1,28,33,267,5,4,4,2,28,33,77,5,3,4,2,5,4,4,2,28,29,32,77,5,4,4,3,28,33,96,5,3,4,3,5,4,4,3,28,29,32,96,5,4,4,4,28,33,115,5,3,4,4,5,4,4,4,28,29,32,115,5,3,36,4,5,28,51,4,6,30,2,33,146,7,7,35,1,30,1,34,1,7,7,35,2,30,1,34,1,32,265,5,3,36,4,5,28,51,4,8,30,2,36,24,33,174,34,1,5,3,36,4,5,28,51,4,9,30,2,33,215,5,3,4,10,5,4,4,11,28,36,24,33,193,34,1,4,12,29,5,4,4,13,28,33,213,5,3,4,13,5,4,4,13,28,29,32,213,32,265,5,3,36,4,5,28,51,4,14,30,2,36,24,33,243,34,1,5,3,36,4,5,28,51,4,15,30,2,33,265,5,3,4,14,5,4,4,14,28,36,24,33,262,34,1,4,12,29,32,265,32,267,32,17,7,16,4,17,28,37,0,30,1,34,1,31,0},P={{K={"TextureID",""},C={37,0,4,0,37,1,4,0,28,36,24,33,17,34,1,4,1,29,31,0},P={},U={{1,3},{1,4}},nParams=0},{K={"TextureContent"},C={37,0,4,0,37,1,4,0,28,29,31,0},P={},U={{1,3},{1,4}},nParams=0}},U={{1,29}},nParams=0},{K={1,"FindFirstChild","Doors",2,"Prison_Fences","CellDoors"},C={27,36,4,0,37,0,36,4,1,28,51,4,2,30,2,29,36,4,3,37,0,36,4,1,28,51,4,4,30,2,29,46,37,0,36,4,1,28,51,4,5,39,2,-1,50,3,31,1},P={},U={{1,11}},nParams=0},{K={"Color","Transparency","CanCollide"},C={37,0,5,0,28,33,11,31,0,32,11,37,0,5,0,27,36,4,0,5,0,4,0,28,29,36,4,1,5,0,4,1,28,29,36,4,2,5,0,4,2,28,29,29,31,0},P={},U={{1,41}},nParams=1},{K={"IsA","BasePart","CanCollide","Transparency",0.5},C={5,0,36,4,0,28,51,4,1,30,2,24,33,18,31,0,32,18,37,0,5,0,30,1,34,1,5,0,4,2,3,29,5,0,4,3,4,4,29,31,0},P={},U={{1,87}},nParams=1},{K={"ipairs","GetDescendants","IsA","BasePart","pairs","Parent"},C={37,0,24,33,9,31,0,32,9,27,6,0,46,7,0,37,1,39,0,-1,47,3,6,3,6,2,6,1,56,1,2,3,49,4,49,5,5,1,5,2,5,3,39,2,2,6,5,6,4,5,4,6,3,5,4,1,17,33,176,5,5,33,166,46,7,0,5,5,36,4,1,28,51,39,1,-1,47,3,6,8,6,7,6,6,56,6,7,8,49,4,49,9,5,6,5,7,5,8,39,2,2,6,9,6,4,5,4,6,8,5,4,1,17,33,164,5,9,36,4,2,28,51,4,3,30,2,33,162,5,0,5,9,2,29,37,2,5,9,28,24,33,152,37,3,5,9,30,1,34,1,32,152,37,4,5,9,30,1,34,1,32,162,32,88,32,166,49,6,49,7,49,8,49,9,32,32,7,4,37,2,39,1,3,6,12,6,11,6,10,56,10,11,12,49,13,5,10,5,11,5,12,39,2,1,6,13,5,13,6,12,5,13,1,17,33,246,5,0,5,13,28,24,36,24,33,234,34,1,5,13,4,5,28,24,33,244,37,2,5,13,1,29,32,244,32,193,31,0},P={},U={{1,40},{1,86},{1,41},{1,87},{1,88}},nParams=0},{K={"pairs","Parent","Color","Transparency","CanCollide","table","clear"},C={7,0,37,0,39,1,3,6,2,6,1,6,0,56,0,1,2,49,3,49,4,5,0,5,1,5,2,39,2,2,6,4,6,3,5,3,6,2,5,3,1,17,33,92,5,3,36,33,56,34,1,5,3,4,1,28,33,90,5,3,4,2,5,4,4,2,28,29,5,3,4,3,5,4,4,3,28,29,5,3,4,4,5,4,4,4,28,29,32,90,32,17,7,5,4,6,28,37,0,30,1,34,1,31,0},P={},U={{1,41}},nParams=0},{K={"Toggles","RainbowTools","Value"},C={7,0,4,1,28,4,2,28,38,0,37,0,24,33,23,37,1,30,0,34,1,32,23,31,0},P={},U={{1,27},{1,85}},nParams=0},{K={"Options","GunTransparency","Value",0},C={7,0,4,1,28,4,2,28,38,0,37,0,4,3,19,33,25,37,1,30,0,34,1,32,25,31,0},P={},U={{1,30},{1,84}},nParams=0},{K={"Toggles","CustomGunSounds","Value","SetValue","ipairs"},C={7,0,4,1,28,4,2,28,38,0,37,0,33,102,37,1,30,0,24,33,43,3,38,0,7,0,4,1,28,36,4,3,28,51,3,30,2,34,1,31,0,32,43,46,7,4,37,2,39,0,-1,47,3,6,2,6,1,6,0,56,0,1,2,49,3,49,4,5,0,5,1,5,2,39,2,2,6,4,6,3,5,3,6,2,5,3,1,17,33,100,37,3,5,4,30,1,34,1,32,63,32,108,37,4,30,0,34,1,31,0},P={},U={{1,32},{1,36},{1,68},{1,38},{1,39}},nParams=0},{K={"Toggles","AntiAimEnabled","Value"},C={37,0,7,0,4,1,28,4,2,28,30,1,34,1,31,0},P={},U={{1,66}},nParams=0},{K={"Options","AntiAimRotationTime","Value"},C={7,0,4,1,28,4,2,28,38,0,31,0},P={},U={{1,46}},nParams=0},{K={"Options","AntiAimRandomization","Value"},C={7,0,4,1,28,4,2,28,38,0,31,0},P={},U={{1,47}},nParams=0},{K={"Options","AntiAimPreviewTransparency","Value"},C={7,0,4,1,28,4,2,28,38,0,31,0},P={},U={{1,48}},nParams=0},{K={"Toggles","AntiAimShowPreview","Value","Character"},C={7,0,4,1,28,4,2,28,38,0,37,0,36,33,19,34,1,37,1,36,33,29,34,1,37,2,4,3,28,33,46,37,3,37,2,4,3,28,37,4,30,2,34,1,32,59,37,0,24,33,59,37,5,30,0,34,1,32,59,31,0},P={},U={{1,55},{1,45},{1,14},{1,63},{1,50},{1,60}},nParams=0},{K={"Toggles","AntiAimPreviewRainbow","Value"},C={7,0,4,1,28,4,2,28,38,0,31,0},P={},U={{1,56}},nParams=0},{K={"Toggles","DoorCollision","Value",0},C={7,0,4,1,28,4,2,28,38,0,4,3,38,1,37,0,33,26,37,2,30,0,34,1,32,32,37,3,30,0,34,1,31,0},P={},U={{1,40},{1,43},{1,89},{1,90}},nParams=0},{K={"Toggles","NoSpread","Value",1,"SpreadRadius",0},C={37,0,7,0,4,1,28,4,2,28,27,36,4,3,4,4,29,4,5,30,3,34,1,31,0},P={},U={{1,73}},nParams=0},{K={"Toggles","InfiniteRange","Value",1,"Range",100000},C={37,0,7,0,4,1,28,4,2,28,27,36,4,3,4,4,29,4,5,30,3,34,1,31,0},P={},U={{1,73}},nParams=0},{K={"Toggles","InfiniteAmmo","Value",1,"CurrentAmmo",2,"Local_CurrentAmmo"},C={7,0,4,1,28,4,2,28,33,18,37,0,30,0,34,1,32,38,37,1,3,27,36,4,3,4,4,29,36,4,5,4,6,29,30,2,34,1,31,0},P={},U={{1,75},{1,73}},nParams=0},{K={"Box","Enabled","Toggles","ESPEnabled","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Box","Style","Options","ESPBoxStyle","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Box","Color","Options","ESPBoxColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Box","Rainbow","Toggles","ESPRainbow","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Box","TeamCheck","Toggles","ESPTeamCheck","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"FriendCheck","Toggles","ESPFriendCheck","Value"},C={37,0,4,0,7,1,4,2,28,4,3,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Box","AutoThickness","Toggles","ESPAutothickness","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Box","Thickness","Options","ESPThickness","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Fill","Enabled","Toggles","ESPFillBox","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Fill","Color","Options","ESPFillBoxColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Fill","Opacity",1,"Options","ESPFillOpacity","Value",100},C={37,0,4,0,28,4,1,4,2,7,3,4,4,28,4,5,28,4,6,12,10,29,31,0},P={},U={{1,16}},nParams=0},{K={"Options","ESPTeamColor","Value","TeamColor","BoxBorder","Box Border","BoxFill","Box Fill","Text","HealthBorder","Health Border","HealthFill","Health Fill"},C={7,0,4,1,28,4,2,28,6,0,37,0,4,3,28,4,4,5,0,4,5,28,2,16,29,37,0,4,3,28,4,6,5,0,4,7,28,2,16,29,37,0,4,3,28,4,8,5,0,4,8,28,2,16,29,37,0,4,3,28,4,9,5,0,4,10,28,2,16,29,37,0,4,3,28,4,11,5,0,4,12,28,2,16,29,31,0},P={},U={{1,16}},nParams=0},{K={"TeamColor","DarkenBorders","Toggles","ESPDarkenBorders","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"TeamColor","DarkenAmount","Options","ESPDarkenAmount","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Chams","Color"},C={37,0,4,0,28,4,1,5,0,29,31,0},P={},U={{1,16}},nParams=1},{K={"Chams","Enabled","Value"},C={37,0,4,0,28,4,1,37,1,4,2,28,29,31,0},P={},U={{1,16},{1,101}},nParams=0},{K={"Chams","Rainbow","Toggles","ESPChamsRainbow","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Chams","Transparency","Options","ESPChamsTransparency","Value",100},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,4,5,12,29,31,0},P={},U={{1,16}},nParams=0},{K={"Chams","OutlineColor"},C={37,0,4,0,28,4,1,5,0,29,31,0},P={},U={{1,16}},nParams=1},{K={"Chams","Outline","Toggles","ESPChamsOutline","Value","OutlineTransparency",0,1},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,7,2,4,3,28,4,4,28,33,38,37,0,4,0,28,4,5,4,6,29,32,48,37,0,4,0,28,4,5,4,7,29,31,0},P={},U={{1,16}},nParams=0},{K={"Chams","OutlineTransparency","Options","ESPChamsOutlineTransparency","Value",100,"Outline"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,4,5,12,29,7,2,4,3,28,4,4,28,4,5,21,33,43,37,0,4,0,28,4,6,3,29,32,43,31,0},P={},U={{1,16}},nParams=0},{K={"Chams","AlwaysOnTop","Toggles","ESPChamsAlwaysOnTop","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Tracers","Color"},C={37,0,4,0,28,4,1,5,0,29,31,0},P={},U={{1,16}},nParams=1},{K={"Tracers","Enabled","Value"},C={37,0,4,0,28,4,1,37,1,4,2,28,29,31,0},P={},U={{1,16},{1,104}},nParams=0},{K={"Tracers","Rainbow","Toggles","ESPTracersRainbow","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Tracers","ShowNotInView","Toggles","ESPTracersShowNotInView","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Tracers","Thickness","Options","ESPTracerThickness","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Tracers","Transparency","Options","ESPTracerTransparency","Value",100},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,4,5,12,29,31,0},P={},U={{1,16}},nParams=0},{K={"Tracers","Origin","Options","ESPTracerOrigin","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","Enabled","Value"},C={37,0,4,0,28,4,1,37,1,4,2,28,29,31,0},P={},U={{1,16},{1,106}},nParams=0},{K={"GetTeamNames"},C={37,0,4,0,28,37,1,39,1,-1,31,-1},P={},U={{1,22},{1,9}},nParams=0},{K={"Aimbot","ExcludeTeams","Options","AimbotExcludeTeams","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","PrioritizeTeams","Options","AimbotPrioritizeTeams","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","Bind"},C={37,0,4,0,28,4,1,5,0,29,31,0},P={},U={{1,16}},nParams=1},{K={"Aimbot","Targeting","Options","AimbotTargeting","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","LockAim","Toggles","AimbotLockAim","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","WallCheck","Toggles","AimbotWallCheck","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","TeamCheck","Toggles","AimbotTeamCheck","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","FriendCheck","Toggles","AimbotFriendCheck","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","HealthCheck","Toggles","AimbotHealthCheck","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","MinHealth","Options","AimbotMinHealth","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","Triggerbot","Toggles","AimbotTriggerbot","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","TriggerbotDelay","Options","AimbotTriggerbotDelay","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","Fov","Options","AimbotFov","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","Range","Options","AimbotRange","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","Smoothing","Options","AimbotSmoothing","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","Prediction","Options","AimbotPrediction","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","FovColor","Options","AimbotFovColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","TargetedFovColor","Options","AimbotTargetedFovColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Aimbot","RainbowFov","Toggles","AimbotRainbowFov","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","ShowName","Toggles","ESPShowName","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","ShowDisplayName","Toggles","ESPShowDisplayName","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","ShowWeapon","Toggles","ESPShowWeapon","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","WeaponColor","Options","ESPWeaponColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","NameColor","Options","ESPNameColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","ShowTeam","Toggles","ESPShowTeam","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","TeamTextColor","Options","ESPTeamTextColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","CustomTextColor","Toggles","ESPCustomTextColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","NameScale","Options","ESPNameScale","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Information","Font","Options","ESPFont","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Health","Enabled","Toggles","ESPShowHealth","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Health","BorderColor","Options","ESPHealthBorderColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Health","FillColor","Options","ESPHealthFillColor","Value"},C={37,0,4,0,28,4,1,7,2,4,3,28,4,4,28,29,31,0},P={},U={{1,16}},nParams=0},{K={"Unload"},C={37,0,36,4,0,28,51,30,1,34,1,31,0},P={},U={{1,1}},nParams=0},{K={"SetWatermarkVisibility","Toggles","Watermark","Value"},C={37,0,36,4,0,28,51,7,1,4,2,28,4,3,28,30,2,34,1,31,0},P={},U={{1,1}},nParams=0},{K={1,"os","clock",0.25,"math","round",0,"PerformanceStats","Ping","GetValue","SetWatermark","string","format","leetware | %d FPS | %d ms"},C={37,0,4,0,9,38,0,7,1,4,2,28,30,0,6,0,5,0,37,1,10,4,3,21,33,106,7,4,4,5,28,37,0,5,0,37,1,10,12,39,1,1,38,2,4,6,38,0,5,0,38,1,46,7,4,4,5,28,37,3,4,7,28,4,8,28,36,4,9,28,51,39,1,-1,47,1,6,1,46,37,4,36,4,10,28,51,7,11,4,12,28,4,13,37,2,5,1,39,3,-1,47,1,34,1,32,106,31,0},P={},U={{1,118},{1,119},{1,117},{1,12},{1,1}},nParams=0},{K={0.5,1,"FindFirstChildOfClass","Backpack","Character",0,"ipairs","pairs","Parent","Color","BrickColor","new","Transparency","CanCollide"},C={37,0,5,0,4,0,11,9,4,1,13,38,0,37,1,30,0,34,1,37,2,30,0,34,1,37,3,33,79,37,4,36,4,2,28,51,4,3,30,2,6,1,5,1,33,56,37,5,5,1,30,1,34,1,32,56,37,4,4,4,28,6,2,5,2,33,77,37,5,5,2,30,1,34,1,32,77,32,79,37,6,4,5,20,33,136,37,4,36,4,2,28,51,4,3,30,2,6,3,5,3,33,113,37,7,5,3,30,1,34,1,32,113,37,4,4,4,28,6,4,5,4,33,134,37,7,5,4,30,1,34,1,32,134,32,136,37,8,33,199,46,7,6,37,9,39,0,-1,47,3,6,7,6,6,6,5,56,5,6,7,49,8,49,9,5,5,5,6,5,7,39,2,2,6,9,6,8,5,8,6,7,5,8,1,17,33,197,37,10,5,9,30,1,34,1,32,160,32,199,37,11,33,331,37,12,5,0,9,38,12,37,12,37,13,21,33,229,4,5,38,12,37,14,30,0,34,1,32,229,37,15,4,5,30,1,6,10,7,7,37,16,39,1,3,6,13,6,12,6,11,56,11,12,13,49,14,5,11,5,12,5,13,39,2,1,6,14,5,14,6,13,5,14,1,17,33,329,5,14,36,33,289,34,1,5,14,4,8,28,33,327,5,14,4,9,5,10,29,5,14,4,10,7,10,4,11,28,5,10,30,1,29,5,14,4,12,4,0,29,5,14,4,13,3,29,32,327,32,254,32,335,4,5,38,12,31,0},P={},U={{1,28},{1,67},{1,75},{1,27},{1,14},{1,80},{1,30},{1,83},{1,32},{1,68},{1,38},{1,40},{1,43},{1,42},{1,89},{1,76},{1,41}},nParams=1},{K={"Destroy","Unloaded"},C={3,38,0,3,38,1,3,38,2,37,3,30,0,34,1,37,4,30,0,34,1,37,5,30,0,34,1,37,6,30,0,34,1,37,7,30,0,34,1,37,8,30,0,34,1,37,9,30,0,34,1,37,10,33,71,37,10,36,4,0,28,51,30,1,34,1,1,38,10,32,71,37,11,33,91,37,11,36,4,0,28,51,30,1,34,1,1,38,11,32,91,37,12,33,111,37,12,36,4,0,28,51,30,1,34,1,1,38,12,32,111,37,13,33,131,37,13,36,4,0,28,51,30,1,34,1,1,38,13,32,131,37,14,4,1,2,29,31,0},P={},U={{1,27},{1,40},{1,45},{1,85},{1,84},{1,90},{1,39},{1,74},{1,65},{1,60},{1,23},{1,24},{1,25},{1,26},{1,1}},nParams=0}}
return _run(___l2,_0O_3,_env,_0104)