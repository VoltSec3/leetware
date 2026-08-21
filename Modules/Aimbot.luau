--[[
   ___ _         _       ___         _          _   _           __   ___    
  / __| |_  _ __| |___  | _ \_ _ ___| |_ ___ __| |_(_)___ _ _   \ \ / / | 
 | (__| | || / _` / -_) |  _/ '_/ _ \  _/ -_) _|  _| / _ \ ' \   \ V /| |    
  \___|_|\_, \__,_\___| |_| |_| \___/\__\___\__|\__|_\___/_||_|   \_/ |_|  
         |__/   
  
  https://clydeprotectionde.cloud 
  build 3839E1C8 
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
local _I_O3={27,6,0,5,0,4,0,35,1,29,5,0,31,1}
local _I0O2={"new"}
local _l1I4={{K={"Players","RunService","Workspace","Player","UserInputService","Utils","Settings","GetMouse","CurrentCamera",0,"Drawing","new","Circle","Thickness",2,"Filled","Visible","InputBegan","Connect","InputEnded","RenderStepped","Destroy"},C={5,0,4,0,28,6,1,5,0,4,1,28,6,2,5,0,4,2,28,6,3,5,0,4,3,28,6,4,5,0,4,4,28,6,5,5,0,4,5,28,6,6,5,0,4,6,28,6,7,5,4,36,4,7,28,51,30,1,6,8,5,3,4,8,28,6,9,1,6,10,3,6,11,4,9,6,12,1,6,13,1,6,14,3,6,15,3,6,16,3,6,17,3,6,18,1,6,19,1,6,20,35,1,6,21,7,10,4,11,28,4,12,30,1,6,22,5,22,4,13,4,14,29,5,22,4,15,3,29,5,22,4,16,3,29,35,2,6,23,35,3,6,24,35,4,6,25,35,5,6,26,1,6,27,35,6,6,27,35,7,6,28,35,8,6,29,35,9,6,30,35,10,6,31,35,11,6,32,35,12,6,33,35,13,6,34,35,14,6,35,35,15,6,36,35,16,6,37,35,17,6,38,35,18,6,39,35,19,6,40,35,20,6,41,35,21,6,42,35,22,6,43,35,23,6,44,5,5,4,17,28,36,4,18,28,51,35,24,30,2,6,45,5,5,4,19,28,36,4,18,28,51,35,25,30,2,6,46,5,2,4,20,28,36,4,18,28,51,35,26,30,2,6,47,27,6,48,5,48,4,21,35,27,29,5,48,31,1},P={{K={"type","getgenv","function","_G"},C={7,0,7,1,30,1,4,2,16,36,33,18,34,1,7,1,30,0,36,24,33,26,34,1,7,3,6,1,5,1,36,33,40,34,1,5,1,5,0,28,36,24,33,51,34,1,7,3,5,0,28,31,1},P={},U=nil,nParams=1},{K={"ExcludeTeams","GetTeamName","TeamCheck","Team"},C={37,0,4,0,28,36,24,33,12,34,1,27,6,1,37,1,4,1,28,5,0,30,1,6,2,5,1,5,2,28,33,37,2,31,1,32,37,37,0,4,2,28,36,33,52,34,1,5,0,4,3,28,36,33,62,34,1,37,2,4,3,28,36,33,78,34,1,5,0,4,3,28,37,2,4,3,28,16,31,1},P={},U={{1,7},{1,6},{1,4}},nParams=1},{K={"PrioritizeTeams","GetTeamName",1,0},C={37,0,4,0,28,36,24,33,12,34,1,27,6,1,5,1,37,1,4,1,28,5,0,30,1,28,36,33,33,34,1,4,2,36,24,33,41,34,1,4,3,31,1},P={},U={{1,7},{1,6}},nParams=1},{K={"GetHumanoid","Health",0,"HealthCheck","MinHealth"},C={37,0,4,0,28,5,0,30,1,6,2,5,2,24,36,24,33,28,34,1,5,2,4,1,28,4,2,19,33,35,3,31,1,32,35,5,1,36,24,33,49,34,1,37,1,4,3,28,24,36,24,33,66,34,1,5,2,4,1,28,37,1,4,4,28,21,31,1},P={},U={{1,6},{1,7}},nParams=2},{K={"FriendCheck","IsFriend"},C={37,0,4,0,28,24,33,13,3,31,1,32,13,37,1,4,1,28,37,2,5,0,39,2,-1,31,-1},P={},U={{1,7},{1,6},{1,4}},nParams=1},{K={"GetCharacterPart","Head","CFrame","Position","RaycastParams","new",1,"Character","ipairs","GetPlayers","table","insert","FilterDescendantsInstances","FilterType","Enum","RaycastFilterType","Blacklist","Raycast","Instance","IsDescendantOf"},C={37,0,4,0,28,5,0,4,1,30,2,6,2,5,2,24,33,23,2,31,1,32,23,37,1,4,2,28,4,3,28,6,3,5,2,4,3,28,5,3,10,6,4,7,4,4,5,28,30,0,6,5,27,36,4,6,37,2,4,7,28,29,6,6,5,1,33,159,46,7,8,37,3,36,4,9,28,51,39,1,-1,47,3,6,9,6,8,6,7,56,7,8,9,49,10,49,11,5,7,5,8,5,9,39,2,2,6,11,6,10,5,10,6,9,5,10,1,17,33,157,5,11,37,2,17,36,33,135,34,1,5,11,4,7,28,33,155,7,10,4,11,28,5,6,5,11,4,7,28,30,2,34,1,32,155,32,93,32,159,5,5,4,12,5,6,29,5,5,4,13,7,14,4,15,28,4,16,28,29,37,4,36,4,17,28,51,5,3,5,4,5,5,30,4,6,12,5,12,1,17,36,33,220,34,1,5,12,4,18,28,36,4,19,28,51,5,0,30,2,24,31,1},P={},U={{1,6},{1,9},{1,4},{1,1},{1,3}},nParams=2},{K={"Character","GetHead","math","clamp","tonumber","Range",500,1,1500,"Position","CFrame","Magnitude","WorldToViewportPoint","Z",0,"GetMouseLocation","Vector2","new","X","Y","Fov","WallCheck"},C={5,0,24,36,24,33,14,34,1,5,0,37,0,16,33,21,3,31,1,32,21,5,0,4,0,28,6,4,37,1,4,1,28,5,0,30,1,6,5,5,4,24,36,24,33,51,34,1,5,5,24,33,58,3,31,1,32,58,7,2,4,3,28,7,4,37,2,4,5,28,30,1,36,24,33,80,34,1,4,6,4,7,4,8,30,3,6,6,5,5,4,9,28,37,3,4,10,28,4,9,28,10,4,11,28,5,6,20,33,115,3,31,1,32,115,37,4,5,0,30,1,33,128,3,31,1,32,128,37,5,5,0,30,1,33,141,3,31,1,32,141,37,6,5,0,5,2,30,2,24,33,157,3,31,1,32,157,37,3,36,4,12,28,51,5,5,4,9,28,39,2,2,6,8,6,7,5,2,24,36,33,201,34,1,5,7,4,13,28,4,14,19,36,24,33,201,34,1,5,8,24,33,208,3,31,1,32,208,5,2,24,36,33,218,34,1,5,1,33,273,37,7,36,4,15,28,51,30,1,6,9,7,16,4,17,28,5,7,4,18,28,5,7,4,19,28,30,2,6,10,5,10,5,9,10,4,11,28,37,2,4,20,28,20,33,271,3,31,1,32,271,32,273,5,2,24,36,33,286,34,1,37,2,4,21,28,36,33,299,34,1,37,8,5,4,5,3,30,2,33,306,3,31,1,32,306,2,31,1},P={},U={{1,4},{1,6},{1,7},{1,9},{1,23},{1,26},{1,25},{1,5},{1,27}},nParams=4},{K={"GetMouseLocation","CFrame","Position","ipairs","GetPlayers","Character","Head","WorldToViewportPoint","Vector2","new","X","Y","Magnitude","table","insert","target","priority","cursorDistance","playerDistance",0,"Targeting","Normal","Random","math","random",1,2,"Closest","Furthest"},C={27,6,0,37,0,36,4,0,28,51,30,1,6,1,37,1,4,1,28,4,2,28,6,2,46,7,3,37,2,36,4,4,28,51,39,1,-1,47,3,6,5,6,4,6,3,56,3,4,5,49,6,49,7,5,3,5,4,5,5,39,2,2,6,7,6,6,5,6,6,5,5,6,1,17,33,207,37,3,5,7,2,30,2,33,195,5,7,4,5,28,4,6,28,6,8,37,1,36,4,7,28,51,5,8,4,2,28,30,2,6,9,7,8,4,9,28,5,9,4,10,28,5,9,4,11,28,30,2,6,10,5,10,5,1,10,4,12,28,6,11,5,8,4,2,28,5,2,10,4,12,28,6,12,7,13,4,14,28,5,0,27,36,4,15,5,7,29,36,4,16,37,4,5,7,30,1,29,36,4,17,5,11,29,36,4,18,5,12,29,30,2,34,1,32,195,49,8,49,9,49,10,49,11,49,12,32,49,5,0,26,4,19,16,33,220,1,31,1,32,220,37,5,4,20,28,36,24,33,233,34,1,4,21,6,13,5,13,4,22,16,33,264,5,0,7,23,4,24,28,4,25,5,0,26,30,2,28,4,15,28,31,1,32,264,5,0,4,25,28,6,14,4,26,6,15,5,0,26,6,16,4,25,6,17,5,17,4,19,20,33,300,5,15,5,16,19,33,469,32,307,5,15,5,16,21,33,469,49,18,5,15,6,18,5,0,5,18,28,6,19,3,6,20,5,13,4,27,16,33,345,5,19,4,18,28,5,14,4,18,28,18,6,20,32,446,5,13,4,28,16,33,367,5,19,4,18,28,5,14,4,18,28,20,6,20,32,446,5,19,4,16,28,5,14,4,16,28,20,36,24,33,444,34,1,5,19,4,16,28,5,14,4,16,28,16,36,33,444,34,1,5,19,4,17,28,5,14,4,17,28,18,36,24,33,444,34,1,5,19,4,17,28,5,14,4,17,28,16,36,33,444,34,1,5,19,4,18,28,5,14,4,18,28,18,6,20,5,20,33,456,5,19,6,14,32,456,49,19,49,20,5,15,5,17,9,6,15,32,284,5,14,4,15,28,31,1},P={},U={{1,5},{1,9},{1,1},{1,28},{1,24},{1,7}},nParams=0},{K={"LockAim"},C={37,0,4,0,28,24,33,21,37,1,39,0,1,38,2,37,2,31,1,32,21,37,2,36,33,36,34,1,37,3,37,2,3,2,30,3,33,44,37,2,31,1,32,44,37,1,39,0,1,38,2,37,2,31,1},P={},U={{1,7},{1,29},{1,10},{1,28}},nParams=0},{K={"Character","GetHead","GetRootPart","Prediction",0,"Position","AssemblyLinearVelocity"},C={5,0,36,33,12,34,1,5,0,4,0,28,6,1,37,0,4,1,28,5,0,30,1,6,2,37,0,4,2,28,5,0,30,1,6,3,5,2,24,33,46,1,31,1,32,46,5,3,24,36,24,33,63,34,1,37,1,4,3,28,4,4,19,33,74,5,2,4,5,28,31,1,32,74,5,2,4,5,28,5,3,4,6,28,37,1,4,3,28,11,9,31,1},P={},U={{1,6},{1,7}},nParams=1},{K={"Bind","typeof","EnumItem","KeyCode","UserInputType","type","string","upper","gsub","^ENUM%.KEYCODE%.","","^ENUM%.USERINPUTTYPE%.","MB1","MOUSEBUTTON1","Enum","MouseButton1","MB2","MOUSEBUTTON2","MouseButton2","Name"},C={37,0,4,0,28,6,1,7,1,5,1,30,1,4,2,16,33,44,5,0,4,3,28,5,1,16,36,24,33,40,34,1,5,0,4,4,28,5,1,16,31,1,32,44,7,5,5,1,30,1,4,6,17,33,60,3,31,1,32,60,7,6,4,7,28,5,1,39,1,1,6,1,7,6,4,8,28,5,1,4,9,4,10,39,3,1,6,1,7,6,4,8,28,5,1,4,11,4,10,39,3,1,6,1,5,1,4,12,16,36,24,33,120,34,1,5,1,4,13,16,33,140,5,0,4,4,28,7,14,4,4,28,4,15,28,16,31,1,32,140,5,1,4,16,16,36,24,33,156,34,1,5,1,4,17,16,33,176,5,0,4,4,28,7,14,4,4,28,4,18,28,16,31,1,32,176,5,0,4,3,28,4,19,28,5,1,16,36,24,33,204,34,1,5,0,4,4,28,4,19,28,5,1,16,31,1},P={},U={{1,7}},nParams=1},{K={"Bind","typeof","EnumItem","EnumType","Enum","KeyCode","IsKeyDown","IsMouseButtonPressed","type","string","upper","gsub","^ENUM%.KEYCODE%.","","^ENUM%.USERINPUTTYPE%.","MB1","MOUSEBUTTON1","UserInputType","MouseButton1","MB2","MOUSEBUTTON2","MouseButton2"},C={37,0,4,0,28,6,0,7,1,5,0,30,1,4,2,16,33,63,5,0,4,3,28,7,4,4,5,28,16,33,47,37,1,36,4,6,28,51,5,0,39,2,-1,31,-1,32,47,37,1,36,4,7,28,51,5,0,39,2,-1,31,-1,32,63,7,8,5,0,30,1,4,9,17,33,79,3,31,1,32,79,7,9,4,10,28,5,0,39,1,1,6,0,7,9,4,11,28,5,0,4,12,4,13,39,3,1,6,0,7,9,4,11,28,5,0,4,14,4,13,39,3,1,6,0,5,0,4,15,16,36,24,33,139,34,1,5,0,4,16,16,33,163,37,1,36,4,7,28,51,7,4,4,17,28,4,18,28,39,2,-1,31,-1,32,163,5,0,4,19,16,36,24,33,179,34,1,5,0,4,20,16,33,203,37,1,36,4,7,28,51,7,4,4,17,28,4,21,28,39,2,-1,31,-1,32,203,7,4,4,5,28,5,0,28,6,1,5,1,33,233,37,1,36,4,6,28,51,5,1,39,2,-1,31,-1,32,233,3,31,1},P={},U={{1,7},{1,5}},nParams=0},{K={"Character","FindFirstChild","Head","CameraMode","Enum","LockFirstPerson","CFrame","Position","Magnitude",1.5},C={37,0,4,0,28,6,0,5,0,36,33,25,34,1,5,0,36,4,1,28,51,4,2,30,2,6,1,37,0,4,3,28,7,4,4,3,28,4,5,28,16,33,48,2,31,1,32,48,5,1,36,33,75,34,1,37,1,4,6,28,4,7,28,5,1,4,7,28,10,4,8,28,4,9,19,36,24,33,82,34,1,3,31,1},P={},U={{1,4},{1,9}},nParams=0},{K={"MouseBehavior","Enum","Default"},C={37,0,33,63,37,1,33,45,37,2,39,0,1,38,3,37,4,4,0,37,3,36,33,28,34,1,37,5,36,24,33,42,34,1,7,1,4,0,28,4,2,28,29,32,52,37,4,4,0,37,5,29,1,38,5,3,38,0,3,38,1,32,63,31,0},P={},U={{1,15},{1,16},{1,34},{1,17},{1,5},{1,14}},nParams=0},{K={},C={3,38,0,1,38,1,1,38,2,1,38,3,3,38,4,37,5,30,0,34,1,1,38,6,31,0},P={},U={{1,11},{1,10},{1,19},{1,20},{1,18},{1,35},{1,13}},nParams=0},{K={"math","clamp","tonumber","TriggerbotDelay",0,0.3},C={7,0,4,1,28,7,2,37,0,4,3,28,30,1,36,24,33,22,34,1,4,4,4,4,4,5,39,3,-1,31,-1},P={},U={{1,7}},nParams=0},{K={},C={1,38,0,1,38,1,31,0},P={},U={{1,19},{1,20}},nParams=0},{K={"mouse1press","mouse1release","type","function","pcall"},C={37,0,4,0,30,1,6,0,37,0,4,1,30,1,6,1,7,2,5,0,30,1,4,3,17,36,24,33,40,34,1,7,2,5,1,30,1,4,3,17,33,47,3,31,1,32,47,7,4,5,0,30,1,6,2,7,4,5,1,30,1,6,3,5,2,36,33,72,34,1,5,3,31,1},P={},U={{1,21}},nParams=0},{K={"WorldToViewportPoint","Position","Z",0,"Vector3","new","Size","X",2,"Vector2","Y","Magnitude","math","max",1.25,6},C={37,0,36,4,0,28,51,5,0,4,1,28,39,2,2,6,2,6,1,5,2,24,36,24,33,36,34,1,5,1,4,2,28,4,3,19,33,43,1,31,1,32,43,37,0,36,4,0,28,51,5,0,4,1,28,7,4,4,5,28,5,0,4,6,28,4,7,28,4,8,12,4,3,4,3,30,3,9,30,2,6,3,7,9,4,5,28,5,3,4,7,28,5,3,4,10,28,30,2,7,9,4,5,28,5,1,4,7,28,5,1,4,10,28,30,2,10,4,11,28,6,4,7,12,4,13,28,5,4,4,14,11,4,15,39,2,-1,31,-1},P={},U={{1,9}},nParams=1},{K={"GetMouseLocation","math","huge","ipairs","GetPlayers","GetHead","WorldToViewportPoint","Position","Vector2","new","X","Y","Magnitude"},C={37,0,36,4,0,28,51,30,1,6,0,1,6,1,7,1,4,2,28,6,2,46,7,3,37,1,36,4,4,28,51,39,1,-1,47,3,6,5,6,4,6,3,56,3,4,5,49,6,49,7,5,3,5,4,5,5,39,2,2,6,7,6,6,5,6,6,5,5,6,1,17,33,209,37,2,4,5,28,5,7,30,1,6,8,5,8,36,33,100,34,1,37,3,5,7,3,3,2,30,4,33,197,37,4,36,4,6,28,51,5,8,4,7,28,39,2,2,6,10,6,9,7,8,4,9,28,5,9,4,10,28,5,9,4,11,28,30,2,5,0,10,4,12,28,6,11,37,5,5,8,30,1,6,12,5,10,36,33,163,34,1,5,12,36,33,173,34,1,5,11,5,12,19,36,33,183,34,1,5,11,5,2,18,33,195,5,7,6,1,5,11,6,2,32,195,32,197,49,8,49,9,49,10,49,11,49,12,32,46,5,1,31,1},P={},U={{1,5},{1,1},{1,6},{1,28},{1,9},{1,40}},nParams=0},{K={"Triggerbot","os","clock"},C={37,0,4,0,28,24,36,24,33,15,34,1,37,1,24,33,27,37,2,30,0,34,1,31,0,32,27,37,3,30,0,6,0,5,0,36,33,45,34,1,5,0,37,4,17,36,33,59,34,1,37,5,5,0,3,3,2,30,4,6,1,5,1,24,33,76,37,2,30,0,34,1,31,0,32,76,7,1,4,2,28,30,0,6,2,37,6,5,0,17,33,107,5,0,38,6,5,2,37,7,30,0,9,38,8,32,107,37,8,36,33,119,34,1,5,2,37,8,21,33,144,37,9,30,0,24,33,138,37,2,30,0,34,1,31,0,32,138,5,2,38,8,32,144,31,0},P={},U={{1,7},{1,11},{1,38},{1,41},{1,4},{1,28},{1,19},{1,37},{1,20},{1,39}},nParams=0},{K={"MouseBehavior","Enum","LockCenter"},C={37,0,36,24,33,10,34,1,37,1,33,16,31,0,32,16,37,2,36,24,33,29,34,1,37,3,4,0,28,38,4,37,5,30,0,36,33,51,34,1,37,4,7,1,4,0,28,4,2,28,17,33,65,7,1,4,0,28,4,2,28,38,4,32,65,37,5,39,0,1,38,6,2,38,0,3,38,7,37,3,4,0,7,1,4,0,28,4,2,28,29,31,0},P={},U={{1,15},{1,18},{1,13},{1,5},{1,14},{1,34},{1,16},{1,17}},nParams=0},{K={"GetMouseLocation","Position","Radius","Fov","Visible","Enabled","RainbowFov","RainbowSpeed",1,"Color","Color3","fromHSV","TargetedFovColor","FovColor"},C={37,0,6,0,37,1,36,4,0,28,51,30,1,6,1,37,2,4,1,5,1,29,37,2,4,2,5,0,4,3,28,29,37,2,4,4,5,0,4,5,28,29,5,0,4,6,28,33,82,37,3,5,0,4,7,28,9,4,8,13,38,3,37,2,4,9,7,10,4,11,28,37,3,4,8,4,8,30,3,29,32,115,37,4,36,33,91,34,1,37,5,33,105,37,2,4,9,5,0,4,12,28,29,32,115,37,2,4,9,5,0,4,13,28,29,31,0},P={},U={{1,7},{1,5},{1,22},{1,12},{1,10},{1,11}},nParams=0},{K={"Enabled","MouseBehavior","Enum","LockCenter"},C={37,0,4,0,28,24,36,24,33,19,34,1,37,1,5,0,30,1,24,33,25,31,0,32,25,37,2,30,0,24,36,33,49,34,1,37,3,4,1,28,7,2,4,1,28,4,3,28,17,33,55,31,0,32,55,2,38,4,37,3,4,1,28,38,5,37,2,30,0,36,33,85,34,1,37,5,7,2,4,1,28,4,3,28,17,33,99,7,2,4,1,28,4,3,28,38,5,32,99,3,38,6,31,0},P={},U={{1,7},{1,32},{1,34},{1,5},{1,11},{1,13},{1,18}},nParams=2},{K={},C={37,0,5,0,30,1,24,33,13,31,0,32,13,37,1,30,0,34,1,31,0},P={},U={{1,32},{1,36}},nParams=1},{K={"CurrentCamera","Enabled","MouseBehavior","Enum","Default","math","clamp","tonumber","Smoothing",5,1,100,"CFrame","new","Position","Lerp"},C={37,0,4,0,28,38,1,37,1,24,33,16,31,0,32,16,37,2,30,0,34,1,37,3,4,1,28,24,36,24,33,37,34,1,37,4,24,33,79,37,5,30,0,34,1,37,6,36,33,57,34,1,37,7,30,0,24,33,77,37,8,4,2,7,3,4,2,28,4,4,28,29,3,38,6,32,77,32,247,37,9,30,0,24,33,96,37,5,30,0,34,1,31,0,32,96,37,10,36,33,108,34,1,37,7,30,0,24,36,33,115,34,1,37,11,33,133,37,12,30,0,34,1,2,38,13,3,38,6,31,0,32,133,37,14,30,0,6,1,37,15,5,1,30,1,6,2,5,2,33,232,37,16,30,0,34,1,7,5,4,6,28,7,7,37,3,4,8,28,30,1,36,24,33,179,34,1,4,9,4,10,4,11,30,3,4,11,12,6,3,7,12,4,13,28,37,1,4,12,28,4,14,28,5,2,30,2,6,4,37,1,4,12,37,1,4,12,28,36,4,15,28,51,5,4,5,3,30,3,29,32,241,1,38,17,37,12,30,0,34,1,37,18,30,0,34,1,31,0},P={},U={{1,3},{1,9},{1,44},{1,7},{1,11},{1,36},{1,17},{1,34},{1,5},{1,33},{1,16},{1,15},{1,35},{1,18},{1,30},{1,31},{1,43},{1,10},{1,42}},nParams=1},{K={"Disconnect","Visible","Remove"},C={37,0,36,4,0,28,51,30,1,34,1,37,1,36,4,0,28,51,30,1,34,1,37,2,36,4,0,28,51,30,1,34,1,37,3,4,1,3,29,37,3,36,4,2,28,51,30,1,34,1,37,4,30,0,34,1,31,0},P={},U={{1,45},{1,46},{1,47},{1,22},{1,36}},nParams=1}},U=nil,nParams=1}}
return _run(_I0O2,_I_O3,_env,_l1I4)