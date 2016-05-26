#! /bin/bash

set -e

# Copy files from $JENKINS_REFDIR into JENKINS_HOME
# So the initial JENKINS_HOME is set with expected content. 
# Don't override, as this is just a reference setup, and use from UI 
# can then change this, upgrade plugins, etc.
copy_reference_file() {
  f=${1%/} 
  rel=${f#$JENKINS_REFDIR/}
  dir=$(dirname ${rel})
  destdir=$JENKINS_HOME/${dir}
  destfile=$JENKINS_HOME/${rel}
  pinfile=${destfile}.pinned
  mkdir -p $destdir
  cp -puv $f $destdir
  # pin plugins on initial copy
  [[ $rel == plugins/*.jpi && ! -f $pinfile ]] && touch $pinfile
}

do_copy_files() {
  export -f copy_reference_file
  gosu $UNAME bash -c 'echo "--- BEGIN Copying files at $(date)" | tee -a $REFCOPY_LOGFILE'
  find $JENKINS_REFDIR/ -type f -exec gosu $UNAME bash -c "copy_reference_file '{}' | tee -a $REFCOPY_LOGFILE" \;
  gosu $UNAME bash -c 'echo "--- END   Copying files at $(date)" | tee -a $REFCOPY_LOGFILE'
}

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  do_copy_files
  # ensure correct permissions on filesystems
  chown -R $UNAME:$GNAME $JENKINS_HOME $JENKINS_REFDIR $JENKINS_INSTALLDIR $JENKINS_BACKUPDIR $JENKINS_WEBROOT
  eval exec gosu $UNAME java $JAVA_OPTS -jar $JENKINS_INSTALLDIR/jenkins.war $JENKINS_OPTS "$@"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"

