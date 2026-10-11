# Resizes the browser for one block and puts it back, waiting for both
# resizes to land.
#
# Locally the suite drives Firefox through Xvfb, where a resize isn't
# applied by the time the call returns. An example that reads the
# window size straight after another example's restore can record the
# small size as its "original", and then every later example runs at
# phone width. Waiting for the size to settle closes that gap.
module WindowSize
  def at_window_size(width, height)
    window = page.driver.browser.manage.window
    original = window.size
    resize_and_settle(window, width, height)
    yield
  ensure
    resize_and_settle(window, original.width, original.height) if original
  end

  private

  def resize_and_settle(window, width, height)
    window.resize_to(width, height)
    40.times do
      break if (window.size.width - width).abs <= 2

      sleep 0.05
    end
  end
end

RSpec.configure do |config|
  config.include WindowSize, type: :system
end
