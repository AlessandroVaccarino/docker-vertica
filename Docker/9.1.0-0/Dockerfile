FROM ubuntu:14.04
LABEL  alessandrov87 (https://github.com/AlessandroVaccarino)

ENV VERTICA_VERSION 9.1.0

# Install dev tools
RUN apt-get update -y \
&&  apt-get upgrade -y \
&&  apt-get install -y openssh-server \
                       openssh-client \
                       mcelog \
                       gdb \
                       sysstat \
                       dialog \
                       curl \
&&  apt-get clean

# Set UTF-8 Locale
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

# Create Vertica user and set default shell to bash, as required by Vertica
RUN groupadd -r verticadba \
&&  useradd -r -m -g verticadba dbadmin \
&&  chsh -s /bin/bash dbadmin \
&&  chsh -s /bin/bash root \
&&  rm /bin/sh \
&&  ln -s /bin/bash /bin/sh

ENV SHELL "/bin/bash"

# Copy Vertica deb installers
RUN mkdir /srv/setup
COPY software/vertica-console_9.1.0-0_amd64.deb /srv/setup
COPY software/vertica_9.1.0-0_amd64.deb /srv/setup

# Pre-installation steps
# Disable Transparent Hugepages
RUN echo "kernel/mm/transparent_hugepage/enabled = never" >> /etc/sysfs.conf
# Create Vertica data and Swap folders
RUN mkdir -p /srv/vertica/db
RUN mkdir -p /swap

# Install Vertica
RUN dpkg -i /srv/setup/vertica_9.1.0-0_amd64.deb
RUN /opt/vertica/sbin/install_vertica \
        --license CE \
        --accept-eula \
        --hosts localhost  \
        --deb /srv/setup/vertica_9.1.0-0_amd64.deb \
        --data-dir /srv/vertica/db \
        --dba-user dbadmin \
        --failure-threshold NONE

# Install Vertica Console
RUN dpkg -i /srv/setup/vertica-console_9.1.0-0_amd64.deb

# Remove setup files
RUN rm /srv/setup/vertica-console_9.1.0-0_amd64.deb
RUN rm /srv/setup/vertica_9.1.0-0_amd64.deb
RUN rm -R /srv/setup

# Copy bootstrap.sh file
COPY bootstrap.sh /etc

# Expose ports
EXPOSE 5433
EXPOSE 5450