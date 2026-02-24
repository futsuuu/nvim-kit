local System = require('___kit___.kit.System')

describe('kit.System', function()
  describe('LineBuffering', function()
    it('should buffering by line (no ignore empty)', function()
      local expects = {
        '1',
        '',
        '2',
        '',
        '',
        '3',
        '',
        '',
      }
      local c = 1
      local buffer = System.LineBuffering
        .new({
          ignore_empty = false,
        })
        :create(function(text)
          assert.are.equal(text, expects[c])
          c = c + 1
        end)
      buffer.write('1\n')
      buffer.write('\n')
      buffer.write('2')
      buffer.write('\n\n')
      buffer.write('\n3')
      buffer.write('\n')
      buffer.write('\n')
      buffer.close()
      assert.are.equal(c, 9)
    end)

    it('should buffering by line (ignore empty)', function()
      local expects = {
        '1',
        '2',
        '3',
      }
      local c = 1
      local buffer = System.LineBuffering
        .new({
          ignore_empty = true,
        })
        :create(function(text)
          assert.are.equal(text, expects[c])
          c = c + 1
        end)
      buffer.write('1\n')
      buffer.write('\n')
      buffer.write('2')
      buffer.write('\n\n')
      buffer.write('\n3')
      buffer.close()
    end)

    it('should handle close() with long content without trailing newline', function()
      local consumed = {}
      local buffer = System.LineBuffering
        .new({ ignore_empty = false })
        :create(function(text)
          table.insert(consumed, text)
        end)
      buffer.write('0123456789abcdef')
      buffer.close()
      assert.are.same(consumed, { '0123456789abcdef' })
    end)

    it('should handle close() with NUL byte at position 10 (git stash format)', function()
      local consumed = {}
      local buffer = System.LineBuffering
        .new({ ignore_empty = false })
        :create(function(text)
          table.insert(consumed, text)
        end)
      buffer.write('stash@{0}\0WIP on main: some stash message')
      buffer.close()
      assert.are.same(consumed, { 'stash@{0}\0WIP on main: some stash message' })
    end)

    it('should not treat carriage return as line break', function()
      local consumed = {}
      local buffer = System.LineBuffering
        .new({ ignore_empty = false })
        :create(function(text)
          table.insert(consumed, text)
        end)
      buffer.write('a\rb')
      buffer.close()
      assert.are.same(consumed, { 'a\rb' })
    end)

    it('should ignore empty writes until close', function()
      local consumed = {}
      local buffer = System.LineBuffering
        .new({ ignore_empty = false })
        :create(function(text)
          table.insert(consumed, text)
        end)
      buffer.write('')
      buffer.write('')
      buffer.close()
      assert.are.same(consumed, { '' })
    end)
  end)
  describe('DelimiterBuffering', function()
    it('should buffering by delimiter', function()
      local buffer, consumed
      consumed = {}
      buffer = System.DelimiterBuffering.new({ delimiter = '\t\t\n' }):create(function(text)
        table.insert(consumed, text)
      end)
      buffer.write('1')
      buffer.write('\t\t\n2\t')
      buffer.write('\t\n3\t\t')
      buffer.write('\n4\t\t\n')
      buffer.write('5')
      buffer.write('\t\t\n')
      buffer.write('6')
      buffer.write('\t\t\n')
      buffer.write('\t')
      buffer.write('\t')
      buffer.write('\n')
      buffer.write('7')
      buffer.close()
      assert.are.same(consumed, { '1', '2', '3', '4', '5', '6', '', '7' })

      consumed = {}
      buffer = System.DelimiterBuffering.new({ delimiter = '\t\t\n' }):create(function(text)
        table.insert(consumed, text)
      end)
      buffer.write('1\t\t\n2\t\t\n3\t\t\n4\t\t\n5\t\t\n6\t\t\n\t\t\n7')
      buffer.close()
      assert.are.same(consumed, { '1', '2', '3', '4', '5', '6', '', '7' })
    end)

    it('should handle delimiter split across chunks', function()
      local consumed = {}
      local buffer = System.DelimiterBuffering.new({ delimiter = 'abc' }):create(function(text)
        table.insert(consumed, text)
      end)
      buffer.write('a')
      buffer.write('bc')
      buffer.write('d')
      buffer.close()
      assert.are.same(consumed, { '', 'd' })
    end)

    it('should handle consecutive delimiters across chunks', function()
      local consumed = {}
      local buffer = System.DelimiterBuffering.new({ delimiter = 'abc' }):create(function(text)
        table.insert(consumed, text)
      end)
      buffer.write('ab')
      buffer.write('cabc')
      buffer.close()
      assert.are.same(consumed, { '', '' })
    end)

    it('should handle delimiters with leading content', function()
      local consumed = {}
      local buffer = System.DelimiterBuffering.new({ delimiter = 'abc' }):create(function(text)
        table.insert(consumed, text)
      end)
      buffer.write('1ab')
      buffer.write('c2')
      buffer.write('abc3')
      buffer.close()
      assert.are.same(consumed, { '1', '2', '3' })
    end)
  end)
end)
