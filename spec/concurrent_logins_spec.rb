require 'rails_helper'

# TODO: the timings are really long but don't show up as that long on the server side. 
# Makes me think that things are not really happening concurrently on the client side
# e.g. maybe the selenium server is executing the request/responses serially instead of
# concurrently. Look into using a grid hub with nodes to actually run things concurrently.

################
# IMPORTANT: 
###############
# To run this test add the following file with an email address per line that exists in course_id
file_with_emails=File.expand_path('test_inputs/emails.txt', __dir__)
course_id=57

unless File.file?(file_with_emails)
  raise "To run the concurrent_logins_spec.rb, create a '#{file_with_emails}' file in the spec folder with a list of emails to use (one per line) who are in course #{course_id}." 
end
emails = Queue.new
File.open(file_with_emails).each { |line| emails << line.strip! unless line.blank? || line.start_with?("#") }
num_concurrent_users = emails.size

describe "Load Test - concurrent logins", :capybara, js: true do

  before do 
    puts "\n###### Starting load test with #{num_concurrent_users} concurrent logins for course #{course_id}"
    @concurrent_requests = num_concurrent_users.times.map do |i|
      Thread.new do
        # Wait a random N second delay before this thread starts (up to 30 seconds) just to be more realistic
        # about the number of concurrent logins happening (e.g. not all at the exact same moment)
        sleep(rand(30)) 
        email = emails.pop()
        times = []
        session = nil
        Benchmark.benchmark('', 15, nil, "Log-in:", "Read response:") do |x|

          times << Benchmark.measure() { 
            session = Capybara::Session.new(:selenium)
            session.visit "/login/cas/1?thread=#{i}"
            session.fill_in 'username', with: email
            session.fill_in 'password', with: 'test1234'
            session.click_button 'Log in'
          }
  
          times <<  Benchmark.measure() {
            # based on the last page the user visited, they could be sent anywhere.
            # just make sure the Braven header is there and this course is in the courses dropdown
            expect(session).to have_css('#header-logo'), "expected #header-logo after #{email} logged in"
            expect(session).to have_css('#courses_menu_item > a'), "expected #courses_menu_item after #{email} logged in"
            expect(session).to have_selector(:css, "a[href=\"/courses/#{course_id}\"]"), "expected link to /courses/#{course_id} after #{email} logged in"
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
    puts "\n###### Finished running load test for #{num_concurrent_users} simulaneous logins to course #{course_id}"
  end

  it "returns a result for each concurrent login request" do
    expect(@results.count).to eq num_concurrent_users
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
