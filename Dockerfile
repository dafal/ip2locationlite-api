# Use the official Ruby image as a parent image
FROM ruby:3.2

# Set the working directory in the container to /usr/src/app
WORKDIR /usr/src/app

# Copy the Gemfile and Gemfile.lock into the container at /usr/src/app
COPY Gemfile Gemfile.lock ./

# Install the dependencies specified in Gemfile
RUN bundle install

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Inform Docker that the container listens on the specified network ports at runtime.
EXPOSE 4567

CMD ["bundle", "exec", "puma", "--port", "4567", "--threads", "0:50"]