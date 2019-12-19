require 'rails_helper'

# Note: even though this test spawns off a number of threads to make concurrent requests,
# it appears that they actual level of concurrency is determined by the number of chrome
# docker container nodes there are in the Grid (see docker-compose.yml). 
# You'll notice that the timings get longer and longer for later threads. 
# E.g. if there are 30 requests and each takes 5-8 seconds, with 3 chrome nodes,
# only 3 at a time are actually executing concurrently while the others are waiting for their
# turn

describe "Load Test - concurrent logins", :capybara, js: true do

  before do 
    test_message = "load test with #{@num_concurrent_users} concurrent logins for course #{@course_id}"
    puts "\n###### Starting #{test_message}"
    @concurrent_requests = @num_concurrent_users.times.map do |i|
      Thread.new do
        # Wait a random N second delay before this thread starts (up to 30 seconds) just to be more realistic
        # about the number of concurrent logins happening (e.g. not all at the exact same moment)
        sleep(rand(30)) 
        email = @emails.pop()
        times = []
        session = nil
        Benchmark.benchmark('', 15, nil, "Log-in:") do |x|

          times << Benchmark.measure() { 
            # See support/helpers/login.rb
            session = login(email)
            #puts "#{session.body}"
          }

          puts "\nThread #{i} timings for user: #{email}"
          # If we return this from this block, the Benchmark.benchmark() will report them with the labels we passed in.
          # This way we can report them as a grid for this thread instead of interspersed.
          times 
        end
        Thread.current[:result] = "Thread #{i} done"
      rescue => e
        puts "### Caught exception in Thread #{i} for #{email}: #{e.inspect}"
        raise
      end
    end
  
    @results = @concurrent_requests.map do |th|
      th.join
    end
    puts "\n###### Finished #{test_message}"
  end

  it "returns a result for each concurrent test" do
    expect(@results.count).to eq @num_concurrent_users
  end
end

############
# Scratch
############
# https://selenium-python.readthedocs.io/api.html
# session.driver.browser.set_script_timeout(60)
# session.driver.browser.set_page_load_timeout(60)
# timeout issues: https://github.com/teamcapybara/capybara/issues/2227
# Maybe I shoiuld turn puma request queue off? https://github.com/puma/puma/blob/master/docs/architecture.md
