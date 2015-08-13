FROM java:8u45-jdk

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y curl zip && \
    rm -rf /var/lib/apt/lists/*

ENV UNAME=jenkins \
    UID=1000 \
    JENKINS_HOME=/var/jenkins_home \
    JENKINS_INSTALLDIR=/usr/share/java/jenkins \
    JENKINS_REFDIR=/usr/share/java/jenkins/ref \
    JENKINS_PORT=8080 \
    JENKINS_SLAVE_AGENT_PORT=50000 \
    JENKINS_WEBROOT=/var/cache/jenkins \
    JENKINS_UC=https://updates.jenkins-ci.org \
    JENKINS_OPTS="--webroot=$JENKINS_WEBROOT --httpPort=$JENKINS_PORT"

# Jenkins is ran with user `$UNAME`, uid = $UID
# If you bind mount a volume from host/volume from a data container, 
# ensure you use same uid
RUN useradd -d "$JENKINS_HOME" -u $UID -m -s /bin/bash $UNAME

# Jenkins home directoy is a volume, so configuration and build history 
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

# `$JENKINS_REFDIR/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.
RUN mkdir -p $JENKINS_REFDIR/init.groovy.d $JENKINS_WEBROOT

# Use tini as subreaper in Docker container to adopt zombie processes 
RUN curl -fL https://github.com/krallin/tini/releases/download/v0.5.0/tini-static -o /bin/tini && chmod +x /bin/tini

COPY init.groovy $JENKINS_REFDIR/init.groovy.d/tcp-slave-agent-port.groovy

ADD https://updates.jenkins-ci.org/latest/jenkins.war $JENKINS_INSTALLDIR/jenkins.war

RUN chown -R $UNAME "$JENKINS_HOME" $JENKINS_REFDIR $JENKINS_INSTALLDIR

# for main web interface:
EXPOSE $JENKINS_PORT

# will be used by attached slave agents:
EXPOSE $JENKINS_SLAVE_AGENT_PORT

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER $UNAME

COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

# from a derived Dockerfile, can use `RUN plugin.sh plugins.txt` to setup $JENKINS_REFDIR/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
