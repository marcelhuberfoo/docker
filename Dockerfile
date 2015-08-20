FROM marcelhuberfoo/arch-openjdk8
MAINTAINER Marcel Huber <marcelhuberfoo@gmail.com>

USER root

RUN pacman -Syy --noconfirm python2 git doxygen graphviz gtk2 openssh && \
    printf "y\\ny\\n" | pacman -Scc

ENV JENKINS_HOME=/var/lib/jenkins \
    JENKINS_INSTALLDIR=/usr/share/java/jenkins \
    JENKINS_BACKUPDIR=/var/backup/jenkins \
    JENKINS_WEBROOT=/var/cache/jenkins \
    JENKINS_REFDIR=/refdata \
    JENKINS_PORT=8080 \
    JENKINS_SLAVE_AGENT_PORT=50000 \
    JENKINS_UC=https://updates.jenkins-ci.org \
    JENKINS_OPTS='--webroot=$JENKINS_WEBROOT --httpPort=$JENKINS_PORT' \
    JAVA_OPTS="-Djenkins.security.ArtifactsPermission=true -Djava.io.tmpdir=/var/tmp"

# Jenkins is run with user `$UNAME`, uid = $UID
# If you bind mount a volume from host/volume from a data container, 
# ensure you use same uid

# `$JENKINS_REFDIR/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.
RUN mkdir -p $JENKINS_INSTALLDIR $JENKINS_REFDIR/init.groovy.d $JENKINS_WEBROOT $JENKINS_BACKUPDIR $JENKINS_HOME

COPY init.groovy $JENKINS_REFDIR/init.groovy.d/tcp-slave-agent-port.groovy

ADD http://mirrors.jenkins-ci.org/war/latest/jenkins.war $JENKINS_INSTALLDIR/jenkins.war

RUN chown -R $UNAME:$GNAME $JENKINS_HOME $JENKINS_REFDIR $JENKINS_INSTALLDIR $JENKINS_BACKUPDIR $JENKINS_WEBROOT

# Jenkins home directory is a volume, so configuration and build history 
# can be persisted and survive image upgrades
VOLUME ["$JENKINS_HOME", "$JENKINS_REFDIR", "$JENKINS_BACKUPDIR"]
WORKDIR $JENKINS_HOME

# main web interface and slave agents port
EXPOSE $JENKINS_PORT $JENKINS_SLAVE_AGENT_PORT

# - from a derived Dockerfile, use `RUN plugins.sh plugins.txt` to setup $JENKINS_REFDIR/plugins from a support bundle
# - using a temporary container and mounting the refdata volume, use `bash -c "plugins.sh plugins.txt"` to setup $JENKINS_REFDIR/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
COPY jenkins.sh /usr/local/bin/jenkins.sh
ENV REFCOPY_LOGFILE=$JENKINS_HOME/reference_copy.log

ENTRYPOINT ["/usr/local/bin/jenkins.sh"]

