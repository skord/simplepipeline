FROM phusion/passenger-full:0.9.14
MAINTAINER Mike Danko <danko@mittdarko.com>
# Proper root home
ENV HOME /root
# This is how we pass environmental variables to nginx children
COPY build/envs.conf /etc/nginx/main.d/envs.conf
# This is a hack inspired by:
# https://github.com/phusion/passenger-docker/issues/28
# in order to get passenger running in the correct environment
ENV PASSENGER_APP_ENV development
ADD build/webapp.sh /etc/my_init.d/webapp.sh
RUN chmod 700 /etc/my_init.d/webapp.sh
# The default command we start our container with
CMD ["/sbin/my_init"]
# What port we expose intra-container
EXPOSE 80
# Allow nginx to start and create a directory for our app
RUN rm -f /etc/service/nginx/down &&\
    mkdir -p /home/app/simplepipeline
# Set the directory we're working from now
WORKDIR /home/app/simplepipeline
# Steps involved in installing gems
ADD Gemfile /home/app/simplepipeline/
ADD Gemfile.lock /home/app/simplepipeline/
RUN chown -R app:app /home/app/simplepipeline
USER app
ENV HOME /home/app
# We're going to use the same container in all environments.
# This could be simplified by creating a data volume container
# for gems specifically (which is more flexible), but for the 
# sake of this demonstration, we're just going to install them
# all, including dev and test.
RUN bundle install --deployment
# Precompile our assets
ADD Rakefile /home/app/simplepipeline/
ADD /config/ /home/app/simplepipeline/config/
ADD /app/assets/ /home/app/simplepipeline/app/assets/
ADD /vendor/ /home/app/simplepipeline/vendor/
USER root
ENV HOME /root
RUN chown -R app:app /home/app/simplepipeline
USER app
ENV HOME /home/app
RUN bundle exec rake assets:precompile
# Add the rest of our application in
ADD / /home/app/simplepipeline
USER root
ENV HOME /root
# One last permissions fix
RUN chown -R app:app /home/app/simplepipeline
# Clean it up so our image isn't gargantuan.
RUN apt-get clean && rm -rf /var/lib/apt/lists* /tmp/* /var/tmp/*
