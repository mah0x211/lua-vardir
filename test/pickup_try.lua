local vardir = require('vardir');
local vd = vardir.new('@');
local keyval = {
    ["/foo"] = {
        qry = '/foo',
        eos = {}
    },
    ["/foo/"] = {
        qry = '/foo/',
        eos = {
            "/foo"
        }
    },
    ["/foo/bar"] ={
        qry = '/foo/bar',
        eos = {
            "/foo",
            "/foo/"
        }
    },
    ["/foo/bar/"] = {
        qry = '/foo/bar/',
        eos = {
            "/foo",
            "/foo/",
            "/foo/bar"
        }
    },
    ["/foo/bar/baz"] = {
        qry = '/foo/bar/baz',
        eos = {
            "/foo",
            "/foo/",
            "/foo/bar",
            "/foo/bar/"
        }
    },
    ["/foo/@bar"] = {
        qry = "/foo/param_bar",
        eos = {
            '/foo',
            '/foo/'
        }
    },
    ["/foo/@bar/baz"] = {
        qry = "/foo/param_bar/baz",
        eos = {
            '/foo',
            '/foo/',
            '/foo/@bar'
        }
    },
    ["/foo/@bar/baz/"] = {
        qry = "/foo/param_bar/baz/",
        eos = {
            '/foo',
            '/foo/',
            '/foo/@bar',
            '/foo/@bar/baz'
        }
    },
};
local val, eos;

for k in pairs( keyval ) do
    ifNotTrue( vd:set( k, k ) )
end

for k, v in pairs( keyval ) do
    val, eos = vd:pickup( v.qry )
    ifNotEqual( val, k )
    ifNotEqual( eos, v.eos )
end



for k, v in pairs({
    ['/foo/@bar'] = {
        qry = '/foo/qux/',
        eos = {
            "/foo",
            "/foo/",
            "/foo/@bar"
        }
    },
    ['/foo/bar/'] = {
        qry = '/foo/bar/qux/',
        eos = {
            "/foo",
            "/foo/",
            "/foo/bar",
            "/foo/bar/"
        }
    },
    ['/foo/bar/baz'] = {
        qry = '/foo/bar/baz/qux/',
        eos = {
            "/foo",
            "/foo/",
            "/foo/bar",
            "/foo/bar/",
            "/foo/bar/baz",
        }
    },
    ['/foo/@bar/baz/'] = {
        qry = "/foo/param_bar/baz/qux",
        eos = {
            '/foo',
            '/foo/',
            '/foo/@bar',
            '/foo/@bar/baz',
            '/foo/@bar/baz/'
        }
    },
}) do
    val, eos = vd:pickup( v.qry )
    ifNotNil( val )
    ifNotEqual( eos, v.eos )
    ifNotEqual( k, eos[#eos] )
end


