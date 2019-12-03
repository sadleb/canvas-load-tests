require 'rails_helper'
require 'benchmark'

# NOTE: before running this test, login to the site, grab a student from course 57
# and set this variable to their email address
course_57_student_email='somestudent@someemail.com'

describe "Proof Of Concept", :capybara do
  it "opens the remote website, logs in, views home page, a wiki page, assignments, and grades", js: true do

    Benchmark.bm(20) do |benchmark|  # Note: 20 is the character padding of the first column
      # See here for how to handle multiple sessions:
      # https://github.com/teamcapybara/capybara#configuring-and-adding-drivers
      session = nil
      benchmark.report("session") { session = Capybara::Session.new(:selenium) }
      benchmark.report("visit login") { session.visit "/login/cas/1" }
      #puts "#{StringIO.new(session.driver.browser.page_source).read}"
      benchmark.report("do login") do 
        session.fill_in 'username', with: course_57_student_email
        session.fill_in 'password', with: 'test1234'
        session.click_button 'Log in'
      end

      # TODO: this is a proof of concept, so i'm not checking for success, 
      # but in a real test make sure and look for things you expect to be on the page
      benchmark.report("homepage") { session.visit "/courses/57" }
      benchmark.report("module 5322") { session.visit "/courses/57/modules/items/5322" }
      benchmark.report("module 5326") { session.visit "/courses/57/modules/items/5326" }
      benchmark.report("assignments") { session.visit "/courses/57/assignments" }
      benchmark.report("assignment 1284") { session.visit "/courses/57/assignments/1284" }
      benchmark.report("grades") { session.visit "/courses/57/grades" }
    end

  end
end

