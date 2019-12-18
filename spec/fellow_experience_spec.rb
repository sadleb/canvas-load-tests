require 'rails_helper'

# Note: even though this test spawns off a number of threads to make concurrent requests,
# it appears that they actual level of concurrency is determined by the number of chrome
# docker container nodes there are in the Grid (see docker-compose.yml). 

describe "Load Test - fellow experience", :capybara, js: true do

  before do 
    puts "\n###### Starting load test with #{@num_concurrent_users} users simulating some common pages a fellow will hit for course #{@course_id}"
    @concurrent_requests = @num_concurrent_users.times.map do |i|
      Thread.new do
        # Wait a random N second delay before this thread starts (up to 30 seconds) just to be more realistic
        # about the number of concurrent logins happening (e.g. not all at the exact same moment)
        sleep(rand(30)) 
        email = @emails.pop()
        times = []
        session = nil
        Benchmark.benchmark('', 30, nil, "Log-in:", "Homepage:", "Module - Onboard:", "Assignments:", "Assignment - Hustle To Career", "Grades:") do |x|

          times << Benchmark.measure() { 
            session = Capybara::Session.new(:selenium)
            session.visit "/login/cas/1?thread=#{i}"
            session.fill_in 'username', with: email
            session.fill_in 'password', with: 'test1234'
            session.click_button 'Log in'
            # based on the last page the user visited, they could be sent anywhere.
            # just make sure the Braven header is there and this course is in the courses dropdown
            expect(session).to have_css('#header-logo'), "expected #header-logo after #{email} logged in"
            expect(session).to have_css('#courses_menu_item > a'), "expected #courses_menu_item after #{email} logged in"
            expect(session).to have_selector(:css, "a[href=\"/courses/#{@course_id}\"]"), "expected link to /courses/#{@course_id} after #{email} logged in"
          }
  
          times <<  Benchmark.measure() {
            session.visit "/courses/#{@course_id}"
            expect(session).to have_selector(:css, '#course_home_content .bz-dynamic-syllabus'), "expected #course_home_content to be .bz-dynamic-syllabus when #{email} hits the homepage"
            expect(session).to have_selector(:css, '#bz-task-part-box .to-do-list'), "expected .to-do-list in #bz-task-part-box when #{email} hits the homepage"
            expect(session).to have_selector(:css, '#section-tabs > li:nth-child(1) > a[class="home active"]'), "expected home tab to be active when #{email} hits the homepage"
            expect(session).to have_selector(:css, '.bz-dynamic-syllabus > .bz-course-part ~ .bz-course-part ~ .bz-course-part'), 
              "expected 3 course-parts (aka sections) on the dynamic syllabus when #{email} hits the homepage"
          }

          times <<  Benchmark.measure() {
            session.visit "/courses/#{@course_id}/pages/onboard-to-braven"
            expect(session).to have_selector(:css, '.bz-module'), "expected .bz-module in onboard-to-braven page for #{email}"
            expect(session).to have_selector(:css, '#bz-progress-bar .bz-graded-question'), "expected progress bar with master questions progres for #{email}"
            expect(session).to have_selector(:css, '#onboarding-reasons > li > input[data-bz-retained="onboarding-002"]'), 
              "expected 'data-bz-retained=\"onboarding-002\"' magic field in onboard-to-braven page for #{email}"
          }

          times <<  Benchmark.measure() {
            session.visit "/courses/#{@course_id}/assignments"
            assignment_selector = "#assignment_#{ASSIGNMENT_FOR_COURSE[@course_id]}"
            expect(session).to have_selector(:css, "#{assignment_selector}"), "expected #{assignment_selector} for #{email} on assignmnts page"
          }

          times <<  Benchmark.measure() {
            assignment_h2c_path = "/courses/#{@course_id}/assignments/#{ASSIGNMENT_FOR_COURSE[@course_id]}"
            session.visit assignment_h2c_path
            assignment_selector = "#assignment_#{ASSIGNMENT_FOR_COURSE[@course_id]}"
            expect(session).to have_selector(:css, "#assignment_show"), "expected #assignment_show for #{email} on assignment = #{assignment_h2c_path}"
            expect(session).to have_selector(:css, ".bz-assignment"), "expected .bz-assignment for #{email} on assignment = #{assignment_h2c_path}"
            # TODO: not sure why this isn't working. Get it working.
            #expect(session).to have_selector(:css, "table.bz-ajax-loaded-rubric .criterion"), "expected inline rubrics to be loaded for #{email} on assignment = #{assignment_h2c_path}"
            # For assignments already past due or submitted, the option to submit won't be there.
            #expect(session).to have_selector(:css, "#submit_assignment"), "expected #submit_assignment for #{email} on assignment = #{assignment_h2c_path}"
          }

          times <<  Benchmark.measure() {
            session.visit "/courses/#{@course_id}/grades"
            expect(session).to have_selector(:css, '#section-tabs > li:nth-child(4) > a[class="grades active"]'), "expected grades tab to be active when #{email} hits the grades page"
            expect(session).to have_selector(:css, "#assignments #grades_summary"), "expected #assignments #grades_summary when #{email} hits the grades page"
            expect(session).to have_selector(:css, "#submission_final-grade"), "expected #submission_final-grade when #{email} hits the grades page"
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
    puts "\n###### Finished running load test for #{@num_concurrent_users} simulaneous logins to course #{@course_id}"
  end

  it "returns a result for each concurrent login request" do
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
