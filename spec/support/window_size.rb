# Keeps the browser window's size from leaking between js system
# examples.
#
# Locally the suite drives Firefox through Xvfb, where a resize isn't
# applied by the time the call returns. Left alone, one example's
# restore can land after the next example's resize and undo it, or an
# example can read the still-shrunk size as its "original" and leave
# every later example at phone width. CI runs headless, where resizes
# are synchronous, so this only ever showed up on a developer's box.
#
# Two pieces:
#   - at_window_size resizes for one block and puts the size back,
#     waiting for each resize to land.
#   - rails_helper remembers the window's size the first time the
#     browser is used and, after every js example, puts it back and
#     waits, whatever the example did.
module WindowSize
  SETTLE_TRIES = 60
  SETTLE_PAUSE = 0.05

  class << self
    attr_reader :default

    def remember_default(page)
      @default ||= page.driver.browser.manage.window.size
    end

    def restore_default(page)
      return unless @default

      window = page.driver.browser.manage.window
      resize_and_settle(window, @default.width, @default.height)
    end

    def resize_and_settle(window, width, height)
      current = window.size
      return if close?(current.width, width) && close?(current.height, height)

      window.resize_to(width, height)
      SETTLE_TRIES.times do
        current = window.size
        break if close?(current.width, width) && close?(current.height, height)

        sleep SETTLE_PAUSE
      end
    end

    def close?(actual, wanted)
      (actual - wanted).abs <= 2
    end
  end

  def at_window_size(width, height)
    window = page.driver.browser.manage.window
    original = window.size
    WindowSize.resize_and_settle(window, width, height)
    yield
  ensure
    WindowSize.resize_and_settle(window, original.width, original.height) if original
  end
end

RSpec.configure do |config|
  config.include WindowSize, type: :system
end
