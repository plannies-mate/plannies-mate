# app/lib/app_helpers_accessor.rb

require_relative 'app_context'

# Provides a helpers accessor
# .
# use `include AppHelpersAccessor` in the base class for instance level helpers accessor
# or `extend AppHelpersAccessor` for class level helpers accessor+
module AppHelpersAccessor
  # App helpers (not to be confused with Sinatra's helpers method)
  def app_helpers
    @app_helpers ||= AppContext.new
  end
end
