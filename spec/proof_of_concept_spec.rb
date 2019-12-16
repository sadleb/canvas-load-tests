require 'rails_helper'
require 'benchmark'

describe "Proof Of Concept", :capybara do
  it "opens the remote website, logs in, views home page, a wiki page, assignments, and grades", js: true do

    user_email_to_test=@emails.pop()

    Benchmark.bm(30) do |benchmark|  # Note: 30 is the character padding of the first column
      # See here for how to handle multiple sessions:
      # https://github.com/teamcapybara/capybara#configuring-and-adding-drivers
      session = nil
      benchmark.report("session:") { session = Capybara::Session.new(:selenium) }
      benchmark.report("visit login:") { session.visit "/login/cas/1" }
      #puts "#{StringIO.new(session.driver.browser.page_source).read}"
      benchmark.report("do login:") do 
        session.fill_in 'username', with: user_email_to_test 
        session.fill_in 'password', with: 'test1234'
        session.click_button 'Log in'
      end

      # TODO: this is a proof of concept, so i'm not checking for success, 
      # but in a real test make sure and look for things you expect to be on the page
      benchmark.report("homepage:") { session.visit "/courses/#{@course_id}" }
      benchmark.report("module - onboard to braven:") { session.visit "/courses/#{@course_id}/pages/onboard-to-braven" }
      benchmark.report("module - network like a pro:") { session.visit "/courses/#{@course_id}/pages/network-like-a-pro" }
      benchmark.report("assignments:") { session.visit "/courses/#{@course_id}/assignments" }
      # TODO: is there a more dynamic way to load some assignment by title for whatever course is configured? 
      if @course_id == 57
        benchmark.report("assignment - H2C:") { session.visit "/courses/57/assignments/1284" }
      end
      benchmark.report("grades:") { session.visit "/courses/#{@course_id}/grades" }
    end

  end
end

