local vardir = require('vardir');
local vd = vardir.new('@');
local keyval = {
    ["/foo"] = "/foo",
    ["/foo/"] = "/foo/",
    ["/foo/@bar"] = "/foo/param_bar",
    ["/foo/@bar/baz"] = "/foo/param_bar/baz",
    ["/foo/@bar/baz/"] = "/foo/param_bar/baz/",
    ["/foo/bar"] = "/foo/bar",
    ["/foo/bar/"] = "/foo/bar/",
    ["/foo/bar/baz"] = "/foo/bar/baz"
};
local val, glob;

for k, v in pairs( keyval ) do
    ifNotTrue( vd:set( k, k ) )
    val, glob = vd:resolve( v )
    ifNotEqual( val, k )
    if #glob > 0 then
        ifNotEqual( glob[1], 'param_bar' )
    end
end


