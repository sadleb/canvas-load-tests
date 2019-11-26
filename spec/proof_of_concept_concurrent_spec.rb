require 'rails_helper'

describe "Proof Of Concept - concurrent requests", :capybara, js: true do

  before do 
    @concurrent_requests = 10.times.map do |i|
      Thread.new do
        puts "Thread #{i}: starting"
        session = Capybara::Session.new(:selenium)
        puts "Thread #{i}: visiting URL"
        session.visit Capybara.app_host + "/health_check?thread=#{i}"
        puts "Thread #{i}: storing response"
        Thread.current[:result] = "Thread #{i} returned: #{StringIO.new(session.driver.browser.page_source).read}"
      end
    end
  
    @results = @concurrent_requests.map do |th|
      th.join
      puts "Result: #{th[:result]}"
    end
  end

  it "results of concurrent requests" do
    expect(@results.count).to eq 10
  end
end


