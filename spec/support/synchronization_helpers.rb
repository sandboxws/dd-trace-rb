require 'English'

module SynchronizationHelpers
  def expect_in_fork
    read_io, write_io = IO.pipe

    # Start in fork
    pid = fork do
      read_io.close

      # Capture test failures
      $stderr.reopen(write_io)

      yield
    end

    write_io.close

    # Wait for fork to finish, retrieve its status.
    Process.wait(pid)
    status = $CHILD_STATUS if $CHILD_STATUS && $CHILD_STATUS.pid == pid

    # Read test failures
    fork_stderr = read_io.read

    # Expect fork and assertions to have completed successfully.
    expect(status && status.success?).to be(true), fork_stderr
  end

  def expect_in_thread(&block)
    # Start in thread
    t = Thread.new(&block)

    # Wait for thread to finish, retrieve its return value.
    status = t.value

    # Expect thread and assertions to have completed successfully.
    expect(status).to be true
  end

  # Defaults to 5 second timeout
  def try_wait_until(attempts: 50, backoff: 0.1)
    loop do
      break if yield(attempts)

      sleep(backoff)
      attempts -= 1

      raise StandardError, 'Wait time exhausted!' if attempts <= 0
    end
  end

  def test_repeat
    # threading model is different on Java, we need to wait for a longer time
    # (like: be over 10 seconds to make sure handle the case "a flush just happened
    # a few milliseconds ago")
    return 300 if PlatformHelpers.jruby?

    30
  end

  class << self
    include SynchronizationHelpers
  end
end
