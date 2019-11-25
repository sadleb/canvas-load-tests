FROM ruby:latest
RUN apt-get update -qq && apt-get install -y build-essential nodejs vim
 
RUN mkdir /app
WORKDIR /app
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN bundle install

CMD ["bash"] 
#CMD ["rails", "server", "-p", "3100", "-b", "0.0.0.0"]
