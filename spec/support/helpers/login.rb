require 'rails_helper'

module Helpers
  module Login

    # Returns a Capybara:Session logged into the website successfully.
    # Throws on errors.
    def login(email)
      session = Capybara::Session.new(:selenium)
      session.visit "/login/cas/1"
      session.fill_in 'username', with: email
      session.fill_in 'password', with: 'test1234'
      session.click_button 'Log in'
      # based on the last page the user visited, they could be sent anywhere.
      # just make sure the Braven header is there and this course is in the courses dropdown
      expect(session).to have_css('#header-logo'), "expected #header-logo after #{email} logged in"
      expect(session).to have_css('#courses_menu_item > a'), "expected #courses_menu_item after #{email} logged in"
      expect(session).to have_selector(:css, "a[href=\"/courses/#{@course_id}\"]"), "expected link to /courses/#{@course_id} after #{email} logged in"
      session
    end

  end
end
