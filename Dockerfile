# Dockerfile for the PDC's Hub service
#
# Base image
#
FROM phusion/passenger-ruby19


# Update system, install Lynx
#
ENV DEBIAN_FRONTEND noninteractive
RUN echo 'Dpkg::Options{ "--force-confdef"; "--force-confold" }' \
      >> /etc/apt/apt.conf.d/local
RUN apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y \
      lynx \
      nmap \
      rsync


# Enable and configure SSH (for AutoSSH user/tunnel)
#
RUN rm -f /etc/service/sshd/down
RUN adduser --quiet --disabled-password --home /home/autossh autossh 2>&1


# Create startup script and make it executable
#
RUN mkdir -p /etc/service/app/
RUN ( \
      echo "#!/bin/bash"; \
      echo "#"; \
      echo "set -e -o nounset"; \
      echo ""; \
      echo ""; \
      echo "# Create Endpoint public keys file (authorized_keys)"; \
      echo "#"; \
      echo "if [ ! -f /home/autossh/.ssh/authorized_keys ]"; \
      echo "then"; \
      echo "  mkdir -p /home/autossh/.ssh/"; \
      echo "  touch /home/autossh/.ssh/authorized_keys"; \
      echo "fi"; \
      echo "chown -R autossh:autossh /home/autossh/.ssh/"; \
      echo ""; \
      echo ""; \
      echo "# Start service"; \
      echo "#"; \
      echo "cd /app/"; \
      echo "chown -R app:app /app/"; \
      echo "/sbin/setuser app bundle install"; \
      echo "/sbin/setuser app bundle exec script/delayed_job start"; \
      echo "/sbin/setuser app bundle exec rails server -p 3002"; \
      echo "/sbin/setuser app bundle exec script/delayed_job stop"; \
    )  \
      >> /etc/service/app/run
RUN chmod +x /etc/service/app/run


# Prepare /app/ folder
#
WORKDIR /app/
COPY . .
RUN chown -R app:app /app/
RUN /sbin/setuser app bundle install --path vendor/bundle
RUN sed -i -e "s/localhost:27017/hubdb:27017/" config/mongoid.yml


# Run Command
#
CMD ["/sbin/my_init"]