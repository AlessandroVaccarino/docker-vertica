#!/bin/bash
set -e

echo " -----> Starting and configuring Vertica"

# Properly shut down Vertica, to avoid inconsistency issues
function vertica_shut_down() {
  echo " -----> Properly shut down Vertica"
  su - dbadmin -c '/opt/vertica/bin/vsql -d database -c "SELECT CLOSE_ALL_SESSIONS();"'
  su - dbadmin -c '/opt/vertica/bin/vsql -d database -c "SELECT MAKE_AHM_NOW();"'
  su - dbadmin -c '/opt/vertica/bin/admintools -t stop_db -d database -i'
}

# Intercept closing of container and proper shut down Vertica
trap "vertica_shut_down" SIGKILL SIGTERM SIGHUP SIGINT EXIT

# Function to handle Vertica DB Restore (Working on...)
: '
importdb(){
    echo " -----> Restoring database"
    rm -rf /srv/vertica/db/tempbak
    mkdir -p /srv/vertica/db/tempbak
    mv /srv/vertica/db/data /srv/vertica/db/tempbak
    mv /srv/vertica/db/catalog /srv/vertica/db/tempbak
    echo " -----> Create fake db, just to initialize Vertica"
    su - dbadmin -c "/opt/vertica/bin/admintools -t create_db -s localhost --skip-fs-checks -d database -c /srv/vertica/db/catalog -D /srv/vertica/db/data"
    vertica_shut_down
    rm -R  /srv/vertica/db/data
    rm -R /srv/vertica/db/catalog
    mv /srv/vertica/db/tempbak/* /srv/vertica/db
    rm -R /srv/vertica/db/tempbak
    su - dbadmin -c "/opt/vertica/bin/admintools -t start_db -d database -i"
}
'

if [ -z "$(ls -A "/srv/vertica/db/data")" ]; then
  # If not data exists, create folders. Then, check DB existence
  mkdir -p /srv/vertica/db/catalog
  mkdir -p /srv/vertica/db/data
  chown -R dbadmin:verticadba "/srv/vertica/db" 
  if [[ ! $(su - dbadmin -c "/opt/vertica/bin/admintools -t list_allnodes" | grep vertica) ]]; then 
    # No database available -> Create one
    echo " -----> Creating an empty DB"
    su - dbadmin -c "/opt/vertica/bin/admintools -t create_db -s localhost --skip-fs-checks -d database -c /srv/vertica/db/catalog -D /srv/vertica/db/data"
  else
    # Database available but no data on folder -> Delete and create new one
    echo " -----> Delete empty DB before create a new one"
    su - dbadmin -c "/opt/vertica/bin/admintools -t drop_db -d database"
    su - dbadmin -c "/opt/vertica/bin/admintools -t create_db -s localhost --skip-fs-checks -d database -c /srv/vertica/db/catalog -D /srv/vertica/db/data"    
  fi
else
  if [[ ! $(su - dbadmin -c "/opt/vertica/bin/admintools -t list_allnodes" | grep vertica) ]]; then 
    # Database not available but data in folder -> Try to import
    #importdb
    # Unable to import from row data -> Inconsistent Epoch state -> So, delete data and create new DB
    echo " -----> Remove old DB data and create an empty one"
    rm -rf /srv/vertica/db/*
    su - dbadmin -c "/opt/vertica/bin/admintools -t create_db -s localhost --skip-fs-checks -d database -c /srv/vertica/db/catalog -D /srv/vertica/db/data"
  else
    # We have both data and DB -> Just start
    echo " -----> DB and data available, just start DB"
    su - dbadmin -c "/opt/vertica/bin/admintools -t start_db -d database -i"
  fi
fi

echo " -----> Vertica is now running"

# If requested, configure Vertica to use HDFS
if [ ! -z "$HDFS" ]; then
  su - dbadmin -c "/opt/vertica/bin/vsql -d database -c \"ALTER DATABASE database SET HadoopConfDir = '/usr/local/hadoop/etc/hadoop';\""
  su - dbadmin -c "/opt/vertica/bin/vsql -d database -c \"SELECT CLEAR_HDFS_CACHES();\""
  su - dbadmin -c "/opt/vertica/bin/vsql -d database -c \"SELECT VERIFY_HADOOP_CONF_DIR();\""
fi  
echo " -----> Vertica set to use HDFS"

# Start Vertica Console service
echo " -----> Starting Vertica Console"
/etc/init.d/vertica-consoled start
echo " -----> Vertica Console is now running"

# Hang session
while true; do
  sleep 1
done