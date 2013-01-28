Name
====

lua-resty-http - Lua HTTP client driver for ngx_lua

Example
=======

    server {
      location /test {
        content_by_lua '
          local http   = require "resty.http"
          local client = http:new()
          client:set_timeout(1000) -- 1 sec

          local ok, err = client:connect("checkip.amazonaws.com", 80)
          if not ok then
            ngx.say("failed to connect: ", err)
            return
          end

          local res, err = client:request({ path = "/" })
          if not res then
            ngx.say("failed to retrieve: ", err)
            return
          end

          -- close connection, or put it into the connection pool
          if res.headers["connection"] == "close" then
            local ok, err = client:close()
            if not ok then
              ngx.say("failed to close: ", err)
              return
            end
          else
            client:set_keepalive(0, 100)
          end

          if res.status >= 200 and res.status < 300 then
            ngx.say("My IP is: " .. res.body)
          else
            ngx.say("Query returned a non-200 response: " .. res.status)
          end
        ';
      }
    }

API
===

new
---
`syntax: client, err = http:new()`

Creates a HTTP object.

connect
-------
`syntax: ok, err = client:connect(host, port?, conf?)`

Attempts to connect to the remote `host` and `port`. Port 80 is assumed, when no port is given.

Before actually resolving the host name and connecting to the remote backend, this method will always look up the connection pool for matched idle connections created by previous calls of this method.

An optional Lua `conf` table can be specified to declare various options:

* `scheme`
: Specifies a scheme, defaults to "http" or "https", depending on the port.
* `path`
: Specifies a default endpoint.

request
-------
`syntax: res, err = client:request(opts?)`

Attempts to retrieve data from a remote location.

An optional Lua `opts` table can be specified to declare various options:

* `method`
: Specifies the request method, defaults to `'get'`.
* `path`
: Specifies the path, defaults to `'/'`.
* `query`
: Specifies query parameters. Accepts either a string or a Lua table.
* `headers`
: Specifies request headers. Accepts a Lua table.

Returns a `res` object containing three attributes:

* `res.status` (number)
: The resonse status, e.g. 200
* `res.headers` (table)
: A Lua table with response headers
* `res.body` (string)
: The plain response body

set_timeout
----------
`syntax: client:set_timeout(time)`

Sets the timeout (in ms) protection for subsequent operations, including the `connect` method.

set_keepalive
------------
`syntax: ok, err = client:set_keepalive(max_idle_timeout, pool_size)`

Puts the current connection immediately into the ngx_lua cosocket connection pool.

You can specify the max idle timeout (in ms) when the connection is in the pool and the maximal size of the pool every nginx worker process.

In case of success, returns `1`. In case of errors, returns `nil` with a string describing the error.

Only call this method in the place you would have called the `close` method instead. Calling this method will immediately turn the current connection into the `closed` state. Any subsequent operations other than `connect()` on the current object will return the `closed` error.

get_reused_times
----------------
`syntax: times, err = client:get_reused_times()`

This method returns the (successfully) reused times for the current connection. In case of error, it returns `nil` and a string describing the error.

close
-----
`syntax: ok, err = client:close()`

Closes the current connection and returns the status.

In case of success, returns `1`. In case of errors, returns `nil` with a string describing the error.

Licence
=======

Some code and documentation parts were (shamelessly) taken from [lua-resty-redis](https://github.com/agentzh/lua-resty-redis), MIT, Copyright by Yichun Zhang.

Greatly inspired by [excon](https://github.com/geemus/excon), MIT, Copyright by Wesley Beary.

This code is covered by MIT License.
(The MIT License)

Copyright (c) 2013 Black Square Media Ltd

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
