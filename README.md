# canvas-load-tests

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite
The load tests run against a remote server. You need to setup the
server it will run against and a list of user logins that will work
for the configured course.

First edit docker-compose.yml `TEST_APP_ROOT_URL` and `TEST_PORT` to point at the remote
server you want to load test. TODO: pass in the ENV vars so you dont have to edit the file.

To setup the list of user logins, add the following file with an email address per 
line that exists in @course_id set in spec/rails_helper.rb:
```test_inputs/emails.txt```
Note: This controls the level of concurrency/load. Adding more emails will cause a bigger load test to run.

Now bring up the containers / environment:
`./restart.sh`
Wait for the hub to be ready. You can see the grid and status at these URLs:
http://localhost:4444/grid/console
http://localhost:4444/wd/hub/status

To run a test, there is a convenient script. Just run: 
`./runtest.sh <insert test file path>`

E.g.
`./runtest.sh spec/proof_of_concept_spec.sh`

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
