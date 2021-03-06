# frozen_string_literal: true

require "abstract_unit"

class ForkTrackerTest < ActiveSupport::TestCase
  def test_object_fork
    read, write = IO.pipe
    called = false

    handler = ActiveSupport::ForkTracker.after_fork do
      called = true
      write.write "forked"
    end

    pid = fork do
      read.close
      write.close
      exit!
    end

    write.close

    Process.waitpid(pid)
    assert_equal "forked", read.read
    read.close

    assert_not called
  ensure
    ActiveSupport::ForkTracker.unregister(handler)
  end

  def test_object_fork_without_block
    read, write = IO.pipe
    called = false

    handler = ActiveSupport::ForkTracker.after_fork do
      called = true
      write.write "forked"
    end

    if pid = fork
      write.close
      Process.waitpid(pid)
      assert_equal "forked", read.read
      read.close
      assert_not called
    else
      read.close
      write.close
      exit!
    end
  ensure
    ActiveSupport::ForkTracker.unregister(handler)
  end

  def test_process_fork
    read, write = IO.pipe
    called = false

    handler = ActiveSupport::ForkTracker.after_fork do
      called = true
      write.write "forked"
    end

    pid = Process.fork do
      read.close
      write.close
      exit!
    end

    write.close

    Process.waitpid(pid)
    assert_equal "forked", read.read
    read.close
    assert_not called
  ensure
    ActiveSupport::ForkTracker.unregister(handler)
  end

  def test_process_fork_without_block
    read, write = IO.pipe
    called = false

    handler = ActiveSupport::ForkTracker.after_fork do
      called = true
      write.write "forked"
    end

    if pid = Process.fork
      write.close
      Process.waitpid(pid)
      assert_equal "forked", read.read
      read.close
      assert_not called
    else
      read.close
      write.close
      exit!
    end
  ensure
    ActiveSupport::ForkTracker.unregister(handler)
  end

  def test_kernel_fork
    read, write = IO.pipe
    called = false

    handler = ActiveSupport::ForkTracker.after_fork do
      called = true
      write.write "forked"
    end

    pid = Kernel.fork do
      read.close
      write.close
      exit!
    end

    write.close

    Process.waitpid(pid)
    assert_equal "forked", read.read
    read.close
    assert_not called
  ensure
    ActiveSupport::ForkTracker.unregister(handler)
  end

  def test_kernel_fork_without_block
    read, write = IO.pipe
    called = false

    handler = ActiveSupport::ForkTracker.after_fork do
      called = true
      write.write "forked"
    end

    if pid = Kernel.fork
      write.close
      Process.waitpid(pid)
      assert_equal "forked", read.read
      read.close
      assert_not called
    else
      read.close
      write.close
      exit!
    end
  ensure
    ActiveSupport::ForkTracker.unregister(handler)
  end

  def test_check
    count = 0
    handler = ActiveSupport::ForkTracker.after_fork { count += 1 }

    assert_no_difference -> { count } do
      3.times { ActiveSupport::ForkTracker.check! }
    end

    Process.stub(:pid, Process.pid + 1) do
      assert_difference -> { count }, +1 do
        3.times { ActiveSupport::ForkTracker.check! }
      end
    end

    assert_difference -> { count }, +1 do
      3.times { ActiveSupport::ForkTracker.check! }
    end
  ensure
    ActiveSupport::ForkTracker.unregister(handler)
  end
end
