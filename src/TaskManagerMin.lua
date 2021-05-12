--@class TaskManagerMin
TaskManager=(function()local self={}self.Stack={}function self.Register(a)if not a.Coroutine then error("[TaskManager] Trying to register a non-Task")end;table.insert(self.Stack,a)end;function self.Update()for b=1,#self.Stack do local a=self.Stack[b]if a and a.Coroutine~=nil then if coroutine.status(a.Coroutine)~="dead"then local c,d=coroutine.resume(a.Coroutine)a.Error=not c;a.LastReturn=d else table.remove(self.Stack,b)if a.Error and a._Catch then a._Catch(a.LastReturn)elseif a._Then~=nil then a._Then(a.LastReturn)end;if a._Finally~=nil then a._Finally()end;a.Finished=true end end end end;return self end)()function Task(e)local self={}self.LastReturn=nil;self.Error=nil;self.Finished=false;if type(e)~="function"then error("[Task] Not a function.")end;self.Coroutine=coroutine.create(e)function self.Then(e)if type(e)~="function"then error("[Task] Then callback not a function.")end;self._Then=e;return self end;function self.Finally(e)if type(e)~="function"then error("[Task] Finally callback not a function.")end;self._Finally=e;return self end;function self.Catch(e)if type(e)~="function"then error("[Task] Catch callback not a function.")end;self._Catch=e;return self end;TaskManager.Register(self)return self end;function await(a)if not a or not a.Coroutine then error("Trying to await non-task object")end;while not a.Finished do coroutine.yield()end;return a.LastReturn end