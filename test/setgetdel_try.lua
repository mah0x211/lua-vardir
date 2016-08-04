local vardir = require('vardir');
local vd = vardir.new('@');
local keys = {
    '/foo',
    '/foo/',
    '/foo/bar',
    '/foo/bar/',
    '/foo/bar/baz',
    '/foo/@bar',
    '/foo/@bar/baz',
    '/foo/@bar/baz/'
};
local v;

for _, k in ipairs( keys ) do
    ifNotTrue( vd:set( k, k ) )
end

for _, k in ipairs( keys ) do
    ifNotEqual( vd:get( k ), k )
end

for _, k in ipairs( keys ) do
    ifNotEqual( vd:del( k ), k )
end

ifNotNil( next( vd.root ) )

