# frozen_string_literal: true

# Helper module for time manipulation in tests
module TimeHelper
  # Temporarily change Time.now and Date.today to a specific time
  def travel_to(time)
    travel_to = time.to_time
    
    original_time = Time.now
    original_date = Date.today
    
    # Freeze time by stubbing Time.now
    allow(Time).to receive(:now).and_return(travel_to)
    
    # Also stub Date.today
    allow(Date).to receive(:today).and_return(travel_to.to_date)
    
    # Execute the block
    begin
      yield
    ensure
      # Restore original behavior
      RSpec::Mocks.space.proxy_for(Time).reset if RSpec::Mocks.space.proxy_for(Time)
      RSpec::Mocks.space.proxy_for(Date).reset if RSpec::Mocks.space.proxy_for(Date)
    end
  end
  
  # Freeze time at current time
  def freeze_time
    travel_to(Time.now) do
      yield
    end
  end
end
