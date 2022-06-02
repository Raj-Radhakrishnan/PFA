#!/bin/sh

working_dir()
{
# gets working directory of script regardless of where it is run from.  Will work even if final directory is path is a symlink

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do  # resolve $SOURCE until the file is no longer a symlink
    returnv="$( cd -P "$(dirname "$SOURCE" )" $$ pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need t resolve it relative to the path where the symlink file was located
done
returnv="$( cd -P "$( dirname "$SOURCE" )" && pwd)"
echo $returnv
}

WRK_DIR=$(working_dir)
source $WRK_DIR/common_functions.include

determine_connections_to_add()
{
  logmsg "Determining connections to add ... \n" true
  # get connections from master fiel which aare missing from platform
  comm -3 $CONNECTION_MASTER_FILE $DB_DIR/PLATFORM_CONNECTIONS.db | egrep -v "\-" | grep -v $'^\t' > $DB_DIR/CONNECTIONS_TO_ADD.db
  cat $DB_DIR/CONNECTIONS_TO_ADD.db | tee -a "$logfile"
  if [ ! -s $DB_DIR/CONNECTIONS_TO_ADD.db ] ; then
    logmsg "No connections found to add \n"
  fi
}

determine_connections_to_remove()
{
  logmsg "Determining connections to remove .... \n" true
  comm -3 $DB_DIR/PLATFORM_CONNECTIONS.db $CONNECTION_MASTER_FILE | egrep -v "^MMI_|^SA|TEST|_LayoutEdit|Admin_|admin_\-" | grep -v $'^\t' > $DB_DIR/CONNECTIONS_TO_REMOVE.db
  cat $DB_DIR/CONNECTIONS_TO_REMOVE.db | tee -a "$logfile"
  if [ ! -s $DB_DIR/CONNECTIONS_TO_REMOVE.db ] ; then
    logmsg "No connections found to remove \n"
  fi
 }

 update_component_connections()
 {
   if [[ -s $DB_DIR/CONNECTIONS_TO_ADD.db || -s $DB_DIR/CONNECTIONS_TO_REMOVE.db ]]; then
      printf "\n Update platform with connection changes ? (y/n) (Ctrl+C to abort ) :"
      if [ $UNATTENDED == false ]; then
        INPUT=""
        while [[ ! "$INPUT" =~ ^[YyNn]$ ]]; do
          read -n 1 -s INPUT;
        done
      fi

      if [[ "$INPUT" =~ [Yy]$ || "$UNATTENDED" == "true" ]]; then
        echo

      if [ -s $DB_DIR/CONNECTIONS_TO_ADD.db ]; then
        export create_connections_input_file=$DB_DIR/CONNECTIONS_TO_ADD.db
        "$WRK_DIR/dplayer_scripts/starts.sh" "$_ION_ENVIRON" "$WRK_DIR/dplayer_scripts/create_connections.ips" | tee -a "$logfile"
      fi

      if [ -s $DB_DIR/CONNECTIONS_TO_REMOVE.db ]; then
        export create_connections_input_file=$DB_DIR/CONNECTIONS_TO_REMOVE.db
        "$WRK_DIR/dplayer_scripts/starts.sh" "$_ION_ENVIRON" "$WRK_DIR/dplayer_scripts/remove_connections.ips" | tee -a "$logfile"
      fi
      fi
    fi
 }

 clear_logs()
 {
   logfile="/ion/logs/platformTopology/LOGS/update_topology.log"
   rm -rf "$logfile" > /dev/null
   mkdir -p /ion/logs/platformTopology/LOGS > /dev/null
   touch "$logfile"
 }

 check_parameter()
 {
  if [[ "$1" == "auto" ]]; then
    UNATTENDED=true
  else
    UNATTENDED=false
  fi
  logmsg "Unattended mode = $UNATTENDED \n" true

 }

 _ION_BASE_DIR=/ion
 source "$WRK_DIR/config/depenencies.config"
 source "/ion/config/PLATFORM_config.include"

 main()
 {
   clear
   clear_logs
   check_parameters "$@"

   check_dependencies
   get_master_connection_list
   get_platform_connections

   determine_connections_to_add
   determine_connections_to_remove\

   update_component_connections
   logmsg "Existing ....\n" true
 }

main "$@"
