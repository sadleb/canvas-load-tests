require 'rails_helper'

# In this proof of concept, each thread executes 2 requests and checks the response.
# So 30 threads is 30 browser sessions, each running two HTTP requests for 60 total
# (ALL AT ONCE). This should be a good start to space out behavior in 30 concurrent
# sessions and run a load test.
# See notes below on going to a higher thread count.
# If we want to mimic more than 30 concurrent users, we're going to have to solve that.
num_threads = 30 

describe "Proof Of Concept - concurrent requests", :capybara, js: true do

  before do 
    @concurrent_requests = num_threads.times.map do |i|
      Thread.new do
        puts "Thread #{i}: starting"
        session = Capybara::Session.new(:selenium)

        puts "Thread #{i}: visiting URL: /health_check?thread=#{i}&visit=1"
        session.visit Capybara.app_host + "/health_check?thread=#{i}&visit=1"
        expect(session).to have_content("canvas ok")

        puts "Thread #{i}: visiting URL: /health_check?thread=#{i}&visit=2"
        session.visit Capybara.app_host + "/health_check?thread=#{i}&visit=2"
        expect(session).to have_content("canvas ok")

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

# On my Mac, moving from 30 to 40 threads makes this lockup and error out. Something inside the selenium
# container trying to create sessions. E.g. this is in the stack trace below the ruby, "session.visit" stuff 
#
# [remote server] sun.reflect.NativeConstructorAccessorImpl(NativeConstructorAccessorImpl.java):-2:in `newInstance0': unknown error: unable to discover open pages (Selenium::WebDriver::Error::UnknownError)
#
#canvastests_1  | 	68: from [remote server] java.lang.Thread(Thread.java):748:in `run'
#canvastests_1  | 	67: from [remote server] java.util.concurrent.ThreadPoolExecutor$Worker(ThreadPoolExecutor.java):624:in `run'
#canvastests_1  | 	66: from [remote server] java.util.concurrent.ThreadPoolExecutor(ThreadPoolExecutor.java):1149:in `runWorker'
#canvastests_1  | 	65: from [remote server] java.util.concurrent.FutureTask(FutureTask.java):266:in `run'
#canvastests_1  | 	64: from [remote server] java.util.concurrent.Executors$RunnableAdapter(Executors.java):511:in `call'
#canvastests_1  | 	63: from [remote server] org.openqa.selenium.remote.server.WebDriverServlet(WebDriverServlet.java):235:in `lambda$handle$0'
#canvastests_1  | 	62: from [remote server] org.openqa.selenium.remote.server.commandhandler.BeginSession(BeginSession.java):65:in `execute'
#canvastests_1  | 	61: from [remote server] org.openqa.selenium.remote.server.NewSessionPipeline(NewSessionPipeline.java):72:in `createNewSession'
#
# Note: I also saw this in the error logs:
# unknown error: DevToolsActivePort file doesn't exist (Selenium::WebDriver::Error::UnknownError)
# See this thread for some things to try but I think it may be a by-product of the session issue above
# https://bugs.chromium.org/p/chromedriver/issues/detail?id=2473

