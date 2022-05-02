return function (self, exportedDefault, metatable)
    -- Hack for allowing Lua metatables to be used as a superclass in roblox-ts

    local tsMetatable = getmetatable(self)

    if tsMetatable ~= metatable then
        repeat
            tsMetatable = getmetatable(tsMetatable.__index)
        until tsMetatable.__index == exportedDefault

        if metatable.__index then
            tsMetatable.__index = function(_,i)
                return metatable.__index(self, i)
            end
        end

        if metatable.__newindex then
            tsMetatable.__newindex = function(_,i,v)
                return metatable.__newindex(self, i, v)
            end
        end

        if metatable.__call then
            tsMetatable.__call = function(_,...)
                return metatable.__call(self, ...)
            end
        end

        if metatable.__concat then
            tsMetatable.__concat = function(_,...)
                return metatable.__concat(self, ...)
            end
        end

        if metatable.__unm then
            tsMetatable.__unm = function(_,...)
                return metatable.__unm(self, ...)
            end
        end

        if metatable.__add then
            tsMetatable.__add = function(_,...)
                return metatable.__add(self, ...)
            end
        end

        if metatable.__sub then
            tsMetatable.__sub = function(_,...)
                return metatable.__sub(self, ...)
            end
        end

        if metatable.__mul then
            tsMetatable.__mul = function(_,...)
                return metatable.__mul(self, ...)
            end
        end

        if metatable.__div then
            tsMetatable.__div = function(_,...)
                return metatable.__div(self, ...)
            end
        end

        if metatable.__mod then
            tsMetatable.__mod = function(_,...)
                return metatable.__mod(self, ...)
            end
        end

        if metatable.__pow then
            tsMetatable.__pow = function(_,...)
                return metatable.__pow(self, ...)
            end
        end

        if metatable.__tostring then
            tsMetatable.__tostring = function(_,...)
                return metatable.__tostring(self, ...)
            end
        end

        if metatable.__metatable then
            tsMetatable.__metatable = function(_,...)
                return metatable.__metatable(self, ...)
            end
        end

        if metatable.__eq then
            tsMetatable.__eq = function(_,...)
                return metatable.__eq(self, ...)
            end
        end

        if metatable.__lt then
            tsMetatable.__lt = function(_,...)
                return metatable.__lt(self, ...)
            end
        end

        if metatable.__le then
            tsMetatable.__le = function(_,...)
                return metatable.__le(self, ...)
            end
        end
    end
end
