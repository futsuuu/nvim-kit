local IO = require('___kit___.kit.IO')
local Async = require('___kit___.kit.Async')
local AsyncTask = require('___kit___.kit.Async.AsyncTask')

describe('kit.Async', function()
  local multiply = Async.async(function(v)
    return AsyncTask.new(function(resolve)
      vim.schedule(function()
        resolve(v * v)
      end)
    end)
  end)

  it('should work like JavaScript Promise', function()
    local num = Async.async(function()
      local num = 2
      num = multiply(num):await()
      num = multiply(num):await()
      return num
    end)():sync()
    assert.are.equal(num, 16)
  end)

  it('should work with exception', function()
    pcall(function()
      Async.run(function()
        error('error')
      end):sync()
    end)
  end)

  describe('.promisify', function()
    it('shoud wrap callback function', function()
      local function wait(ms, callback)
        vim.defer_fn(function()
          callback(nil, 'timeout')
        end, ms)
      end

      local wait_async = Async.promisify(wait)
      assert.equals(wait_async(100):sync(), 'timeout')
    end)
    it('shoud wrap callback function with rest arguments', function()
      local function wait(ms, callback, result)
        vim.defer_fn(function()
          callback(nil, result)
        end, ms)
      end

      local wait_async = Async.promisify(wait, { callback = 2 })
      assert.equals(wait_async(100, 'timeout'):sync(), 'timeout')
    end)
  end)
end)
