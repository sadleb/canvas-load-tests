require 'rails_helper'
require 'benchmark'

# In this proof of concept, each thread executes 2 requests and checks the response.
# So 50 threads is 50 browser sessions, each running two HTTP requests for 100 total
# (ALL AT ONCE). This should be a good starting point to write some scripts that run
# concurrent behavior (with various degrees of spacing it out using thread sleep)
# in order to run a load test.
#
# NOTE: i was able to get from 30 threads up to 50 threads by changing the resource allocation
# of my docker container from 3GB RAM to 4GB and setting the NODE_MAX_INSTANCES and NODE_MAX_SESSIONS
# to something high. 60 threads failed though. This seems to be a memory issue in the selenium 
# container which has to create 100s of chrome instances. See the notes at the bottom of this file for details.
#
num_threads = 50 

describe "Proof Of Concept - concurrent requests", :capybara, js: true do

  before do 
    @concurrent_requests = num_threads.times.map do |i|
      Thread.new do

        puts "Thread #{i}: starting"
        session = Capybara::Session.new(:selenium)

        time = Benchmark.realtime { 
          session.visit "/health_check?thread=#{i}&visit=1" 
        }
        puts "Thread #{i}: visited URL (#{time}s): /health_check?thread=#{i}&visit=1"

        time = Benchmark.realtime { 
          expect(session).to have_content("canvas ok")
        }
        puts "Thread #{i}: read response (#{time}s): /health_check?thread=#{i}&visit=1"

        time = Benchmark.realtime { 
          session.visit "/health_check?thread=#{i}&visit=2" 
        }
        puts "Thread #{i}: visited URL (#{time}s): /health_check?thread=#{i}&visit=2"

        time = Benchmark.realtime { 
          expect(session).to have_content("canvas ok")
        }
        puts "Thread #{i}: read response (#{time}s): /health_check?thread=#{i}&visit=2"

        #Thread.current[:result] = "Thread #{i} done and returning: #{StringIO.new(session.driver.browser.page_source).read}"
        Thread.current[:result] = "Thread #{i} done and returning"
      end
    end
  
    @results = @concurrent_requests.map do |th|
      th.join
      puts "Result: #{th[:result]}"
    end
  end

  it "results of concurrent requests" do
    expect(@results.count).to eq num_threads
  end
end

########################
# Example errors if the thread count is too high (and a good thread that led me to the memory hunch):
#   https://stackoverflow.com/questions/21001652/chrome-driver-error-using-selenium-unable-to-discover-open-pages
#
# unknown error: unable to discover open pages (Selenium::WebDriver::Error::UnknownError)
# /usr/local/lib/ruby/2.6.0/net/protocol.rb:217:in `rbuf_fill': Net::ReadTimeout with #<TCPSocket:(closed)>
# /usr/local/lib/ruby/2.6.0/net/protocol.rb:217:in `wait_readable': stream closed in another thread (IOError)
# 
# Note: I tried to get a Selenium HUB going with multiple nodes but it wasn't working for some reason. If I need
# to get higher concurrency, go back to that attempt. See Dockerfile.seleniumhub
