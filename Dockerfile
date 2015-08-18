FROM java:8u45-jdk

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends install -q -y curl zip && \
    rm -rf /var/lib/apt/lists/*

ENV UNAME=jenkins \
    GNAME=jenkins \
    UID=1000 \
    GID=1000 \
    JENKINS_HOME=/var/lib/jenkins \
    JENKINS_INSTALLDIR=/usr/share/java/jenkins \
    JENKINS_BACKUPDIR=/var/backup/jenkins \
    JENKINS_WEBROOT=/var/cache/jenkins \
    JENKINS_REFDIR=/refdata \
    JENKINS_PORT=8080 \
    JENKINS_SLAVE_AGENT_PORT=50000 \
    JENKINS_UC=https://updates.jenkins-ci.org \
    JENKINS_OPTS='--webroot=$JENKINS_WEBROOT --httpPort=$JENKINS_PORT' \
    JAVA_OPTS="-Djenkins.security.ArtifactsPermission=true -Djava.io.tmpdir=/var/tmp"

# Jenkins is ran with user `$UNAME`, uid = $UID
# If you bind mount a volume from host/volume from a data container, 
# ensure you use same uid
RUN groupadd -g $GID $GNAME && \
    useradd -d "$JENKINS_HOME" --uid $UID --gid $GID -m -s /bin/bash $UNAME

# `$JENKINS_REFDIR/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.
RUN mkdir -p $JENKINS_INSTALLDIR $JENKINS_REFDIR/init.groovy.d $JENKINS_WEBROOT $JENKINS_BACKUPDIR

# Use tini as subreaper in Docker container to adopt zombie processes 
RUN curl -fL https://github.com/krallin/tini/releases/download/v0.5.0/tini-static -o /bin/tini && chmod +x /bin/tini

COPY init.groovy $JENKINS_REFDIR/init.groovy.d/tcp-slave-agent-port.groovy

ADD https://updates.jenkins-ci.org/latest/jenkins.war $JENKINS_INSTALLDIR/jenkins.war

RUN chown -R $UNAME:$GNAME $JENKINS_HOME $JENKINS_REFDIR $JENKINS_INSTALLDIR $JENKINS_BACKUPDIR $JENKINS_WEBROOT

# Jenkins home directory is a volume, so configuration and build history 
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME $JENKINS_REFDIR $JENKINS_BACKUPDIR
WORKDIR $JENKINS_HOME

# for main web interface:
EXPOSE $JENKINS_PORT

# will be used by attached slave agents:
EXPOSE $JENKINS_SLAVE_AGENT_PORT

USER $UNAME

# - from a derived Dockerfile, use `RUN plugins.sh plugins.txt` to setup $JENKINS_REFDIR/plugins from a support bundle
# - using a temporary container and mounting the refdata volume, use `bash -c "plugins.sh plugins.txt"` to setup $JENKINS_REFDIR/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh

ENV REFCOPY_LOGFILE=$JENKINS_HOME/reference_copy.log
COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/jenkins.sh"]

