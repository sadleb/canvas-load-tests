# TODO: write a load test where a bunch of users load, fill out their assignment, and submit it concurrently
require 'rails_helper'

# Note: even though this test spawns off a number of threads to make concurrent requests,
# it appears that they actual level of concurrency is determined by the number of chrome
# docker container nodes there are in the Grid (see docker-compose.yml). 

describe "Load Test - hustle to career project", :capybara, js: true do


  before do 
    test_message = "load test with #{@num_concurrent_users} users simulating loading the Hustle To Career Project for course #{@course_id}"
    puts "\n###### Starting #{test_message}"
    @concurrent_requests = @num_concurrent_users.times.map do |i|
      Thread.new do
        email = @emails.pop()
        times = []
        session = nil
        Benchmark.benchmark('', 30, nil, "Log-in:", "Assignment - Hustle To Career") do |x|

          times << Benchmark.measure() { 
            session = login(email)
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


