require 'rails_helper'

describe "Proof Of Concept", :capybara do
  it "opens the remote website", js: true do

    # See here for how to handle multiple sessions:
    # https://github.com/teamcapybara/capybara#configuring-and-adding-drivers
    session = Capybara::Session.new(:selenium)
    session.visit Capybara.app_host + "/login/cas/1"
    #puts "#{StringIO.new(session.driver.browser.page_source).read}"
    session.fill_in 'username', with: 'someemail@blah.com'
    session.fill_in 'password', with: 'some_password'
    session.click_button 'Log in'
   
    session.visit Capybara.app_host + "/courses/29" 
    session.visit Capybara.app_host + "/courses/29/modules/items/3824" 

  end
end
