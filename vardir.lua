--[[

  Copyright (C) 2016 Masatoshi Teruya

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

  vardir.lua
  lua-vardir
  Created by Masatoshi Teruya on 16/06/13.

--]]

--- assign to local
local byte = string.byte;
local hasChildNode = next;
--- errors
local ESYMBOL = 'invalid segment symbol';
local EFORMAT = 1;
local EALREADY = 2;
local EVUNNAMED = 3;
local EVALREADY = 4;
local ERRSTR = {
    [EFORMAT] = 'cannot use reserved segment name';
    [EALREADY] = 'segment already defined';
    [EVUNNAMED] = 'cannot create unnamed variable segment';
    [EVALREADY] = 'variable segment already defined';
};
--- patterns
local SEG_PATTERN = '/+';
--- symbols
local SYM_TRAIL = '/';
local SYM_VAR = '^';
local SYM_EOS = '#';
--- lookup tables
local RESERVED = {
    [SYM_TRAIL] = true,
    [SYM_VAR] = true,
    [SYM_EOS] = true
};


--- set
-- @param node
-- @param seg
-- @param sym
-- @return node
-- @return err
local function set( node, seg, sym )
    -- error if reserved segment name
    if RESERVED[seg] then
        return nil, EFORMAT;
    -- vnode segment
    elseif byte( seg ) == sym then
        local vnode;

        -- extract varname
        seg = seg:sub( 2 );
        -- variable-segment name length must be greater than 0
        if #seg < 1 then
            return nil, EVUNNAMED;
        -- check trailing-slash
        elseif node[SYM_TRAIL] then
            node = node[SYM_TRAIL];
        end

        -- select variable segment
        vnode = node[SYM_VAR];
        if not vnode then
            vnode = {
                name = seg,
                node = {};
            };
            node[SYM_VAR] = vnode;
        -- variable-segment already defined
        elseif vnode.name ~= seg then
            return nil, EVALREADY;
        end

        return vnode.node;
    -- existing node
    elseif node[seg] then
        return node[seg];
    elseif node[SYM_TRAIL] then
        node = node[SYM_TRAIL];
        if node[seg] then
            return node[seg];
        end
    end

    -- create new node
    node[seg] = {};

    return node[seg];
end


--- get
-- @param node
-- @param seg
-- @param sym
-- @return node
local function get( node, seg, sym )
    if seg then
        if node[SYM_TRAIL] then
            node = node[SYM_TRAIL];
        end

        -- there is not vnode segment
        if byte( seg ) ~= sym then
            return node[seg];
        elseif #seg > 1 and node[SYM_VAR] and node[SYM_VAR].name == seg:sub( 2 ) then
            return node[SYM_VAR].node;
        end
    end
end


--- trace
-- @param node
-- @param seg
-- @param sym
-- @param path
-- @return node
local function trace( node, seg, sym, path )
    if seg then
        if node[SYM_TRAIL] then
            path[#path + 1] = { SYM_TRAIL, node };
            node = node[SYM_TRAIL];
        end

        -- there is not vnode segment
        if byte( seg ) ~= sym then
            path[#path + 1] = { seg, node };
            return node[seg];
        elseif #seg > 1 and node[SYM_VAR] and node[SYM_VAR].name == seg:sub( 2 ) then
            path[#path + 1] = { SYM_VAR, node };
            return node[SYM_VAR].node;
        end
    end
end


--- resolve
-- @param node
-- @param seg
-- @param glob
-- @param node
local function resolve( node, seg, glob )
    if seg then
        if node[SYM_TRAIL] then
            node = node[SYM_TRAIL];
        end

        -- found segment
        if node[seg] then
            return node[seg];
        -- found variable-segment
        elseif node[SYM_VAR] then
            node = node[SYM_VAR];
            glob[node.name] = seg;
            return node.node;
        end
    end
end


--- pickup
-- @param node
-- @param seg
-- @param eos
-- @return node
local function pickup( node, seg, eos )
    if node[SYM_EOS] then
        eos[#eos + 1] = node[SYM_EOS];
    end

    if seg then
        if node[SYM_TRAIL] then
            node = node[SYM_TRAIL];
            if node[SYM_EOS] then
                eos[#eos + 1] = node[SYM_EOS];
            end
        end

        -- found segment
        if node[seg] then
            return node[seg];
        -- found variable-segment
        elseif node[SYM_VAR] then
            node = node[SYM_VAR];
            return node.node;
        end
    end
end


--- traverse
-- @param node
-- @param key
-- @param fn
-- @param ... fn args
-- @return val
-- @return isTrailingSlash
local function traverse( node, key, fn, ... )
    local pos = 1;
    local head, tail = key:find( SEG_PATTERN, 1 );
    local seg;

    while head do
        seg = key:sub( pos, head - 1 );
        -- there is reserved segment name
        if RESERVED[seg] then
            return nil;
        end

        node = fn( node, seg, ... );
        if not node then
            return nil;
        end
        pos = tail + 1;
        head, tail = key:find( SEG_PATTERN, pos );
    end

    -- trailing-slash
    if pos > #key then
        fn( node, nil, ... );
        if not node[SYM_TRAIL] then
            return nil;
        end

        return node[SYM_TRAIL][SYM_EOS], true;
    end

    seg = key:sub( pos );
    -- there is reserved segment name
    if RESERVED[seg] then
        return nil;
    end

    node = fn( node, seg, ... );
    return node and node[SYM_EOS];
end


local Vardir = {};


--- set
-- @param key
-- @param val
-- @return ok
-- @return err
function Vardir:set( key, val )
    local sym = self.sym;
    local node = self.root;
    local pos = 1;
    local head, tail = key:find( SEG_PATTERN, 1 );
    local err;

    while head do
        node, err = set( node, key:sub( pos, head - 1 ), sym );
        if err then
            return false, err;
        end
        pos = tail + 1;
        head, tail = key:find( SEG_PATTERN, pos );
    end

    -- trailing-slash
    if pos > #key then
        local mergenode;

        if node[SYM_TRAIL] then
            return false, EALREADY;
        end

        mergenode = {
            [SYM_EOS] = val
        };
        for k, v in pairs( node ) do
            if k ~= SYM_EOS then
                mergenode[k] = v;
                node[k] = nil;
            end
        end
        node[SYM_TRAIL] = mergenode;
    else
        node, err = set( node, key:sub( pos ), sym );
        if err then
            return false, err;
        end
        node[SYM_EOS] = val;
    end

    return true;
end


--- del
-- @param key
-- @return val
function Vardir:del( key )
    local path = {};
    local val, ts = traverse( self.root, key, trace, self.sym, path );

    -- found
    if val then
        local node = path[#path];

        -- append a trailing-slash node if key has a trailing-slash
        if ts then
            node = { SYM_TRAIL, node[2][node[1]] };
            path[#path + 1] = node;
        end

        -- remove eos
        if node[1] == SYM_VAR then
            node[2][node[1]].node[SYM_EOS] = nil;
        else
            node[2][node[1]][SYM_EOS] = nil;
        end

        -- cleaning-up unused path-node
        for i = #path, 1, -1 do
            node = path[i];
            -- stop if non-empty node
            if node[1] == SYM_VAR then
                if hasChildNode( node[2][node[1]].node ) then
                    break;
                end
            -- stop if non-empty node
            elseif hasChildNode( node[2][node[1]] ) then
                break;
            end
            node[2][node[1]] = nil;
        end
    end

    return val;
end


--- get
-- @param key
-- @return val
function Vardir:get( key )
    return traverse( self.root, key, get, self.sym );
end


--- resolve
-- @param key
-- @return val
-- @return glob
function Vardir:resolve( key )
    local glob = {};
    local val = traverse( self.root, key, resolve, glob );

    return val, glob;
end


--- pickup
-- @param key
-- @return val
-- @return eos
function Vardir:pickup( key )
    local eos = {};
    local val = traverse( self.root, key, pickup, eos );

    return val, eos;
end


--- new
-- @param sym
-- @return instance
local function new( sym )
    assert( type( sym ) == 'string' and #sym == 1, ESYMBOL );

    return setmetatable({
        sym = byte( sym ),
        root = {}
    }, {
        __index = Vardir
    });
end


--- strerror
-- @param errno
-- @return errstr
local function strerror( errno )
    return ERRSTR[errno] or 'unknown error';
end


return {
    new = new,
    strerror = strerror,
    -- errno
    EFORMAT = EFORMAT,
    EALREADY = EALREADY,
    EVUNNAMED = EVUNNAMED,
    EVALREADY = EVALREADY
};
