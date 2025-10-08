wrk.method = "POST"
wrk.body = "Test message from wrk load test"
wrk.headers["Content-Type"] = "text/plain"

counter = 0

request = function()
    counter = counter + 1
    wrk.body = "Message " .. counter .. " at " .. os.time()
    return wrk.format()
end