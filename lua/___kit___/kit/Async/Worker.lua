local uv = require('luv')
local AsyncTask = require('___kit___.kit.Async.AsyncTask')

---@class ___kit___.kit.Async.WorkerOption
---@field public runtimepath string[]

---@class ___kit___.kit.Async.Worker
---@field private runner string
local Worker = {}
Worker.__index = Worker

---Create a new worker.
---@param runner function
function Worker.new(runner)
  local self = setmetatable({}, Worker)
  self.runner = string.dump(runner)
  return self
end

---Call worker function.
---@return ___kit___.kit.Async.AsyncTask
function Worker:__call(...)
  local args_ = { ... }
  return AsyncTask.new(function(resolve, reject)
    uv.new_work(function(runner, args, option)
      args = vim.mpack.decode(args)
      option = vim.mpack.decode(option)

      --Initialize cwd.
      require('luv').chdir(option.cwd)

      --Initialize package.loaders.
      table.insert(package.loaders, 2, vim._load_package)

      --Run runner function.
      local ok, res = pcall(function()
        return require('___kit___.kit.Async.AsyncTask').resolve(assert(loadstring(runner))(unpack(args))):sync(5000)
      end)

      res = vim.mpack.encode({ res })

      --Return error or result.
      if not ok then
        return res, nil
      else
        return nil, res
      end
    end, function(err, res)
      if err then
        reject(vim.mpack.decode(err)[1])
      else
        resolve(vim.mpack.decode(res)[1])
      end
    end):queue(
      self.runner,
      vim.mpack.encode(args_),
      vim.mpack.encode({
        cwd = uv.cwd(),
      })
    )
  end)
end

return Worker
