#!/bin/bash

MAP_YES=false
SESSION_YES=false

while true; do
  IFS=$'\n' read -d '' -r -a lines < maps.txt
  echo -n "Current map is: ${lines[0]}"
  echo
  echo -n "Would you like to change the map ('y' for yes, 'n' for no)? "
  read changeMap

  if [ "$changeMap" == "y" ]; then
    for (( i = 1; i < ${#lines[@]} - 1; i++ )); do
      echo "$i - ${lines[$i]}"
    done
    echo -n "Choose a map ('n' for none to keep current map): "
    read map

    if [ "$map" == "n" ]; then
      echo "Skipping..."
    elif [[ -z $map ]] || (("$map" < "1"))  || (("$map" > "9")); then
      echo "Choose a map 1 - 9 only"
    else
      sed -i "1s/.*/${lines[$map]}/" "maps.txt"
      sed -i "12s/${lines[0]}/${lines[$map]}/" "ark.service"
      echo "You picked: ${lines[$map]}"
      MAP_YES=true
    fi
  elif [ "$changeMap" == "n" ]; then
    echo "Skipping map change step..."
  else
    echo "Invalid choice, type 'y' for yes, 'n' for no."
  fi

  echo -n "Current session name is: ${lines[10]}"
  echo
  echo -n "Would you like to change the session name ('y' for yes, 'n' for no)? "
  read changeSession

  if [ "$changeSession" == "y" ]; then
    echo -n "Type a new name for the server session: "
    read newSessionName
    sed -i "12s/${lines[10]}/$newSessionName/" "ark.service"
    sed -i "11s/${lines[10]}/$newSessionName/" "maps.txt"
    SESSION_YES=true
  elif [ "$changeSession" == "n" ]; then
    echo "Skipping session name change step..."
  else
    echo "Invalid choice, type 'y' for yes, 'n' for no."
  fi

  if $MAP_YES || $SESSION_YES; then
    echo "input server admin password: "
    read PASS
    echo "warning players about server restart, this will take 2 minutes"
    yes broadcast warning! server is restarting in 2 minutes, please log off immediatly and wait for server to reload | ruby ~/srcon-rb/srcon.rb 127.0.0.1 32330 -p "$PASS" --
    sleep 30s
    echo "1:30 left until restart"
    yes broadcast server restart in: 1:30 | ruby ~/srcon-rb/srcon.rb 127.0.0.1 32330 -p "$PASS" --
    sleep 30s
    echo "1 minute left until restart"
    yes broadcast server restart in: 1 minute | ruby ~/srcon-rb/srcon.rb 127.0.0.1 32330 -p "$PASS" --
    sleep 30s
    echo "30 seconds left until restart"
    yes broadcast server restart in: 30 seconds | ruby ~/srcon-rb/srcon.rb 127.0.0.1 32330 -p "$PASS" --
    for (( i = 30; i > 0; i-- )); do
      yes broadcast server restart in: "$i" | ruby ~/srcon-rb/srcon.rb 127.0.0.1 32330 -p "$PASS" --
      echo "$i seconds left until restart"
      sleep 1s
    done

    echo "Killing ark service for restart..."
    systemctl stop ark

    echo "Attempting to copy over updated ark.service file..."
    cp -f "ark.service" "/lib/systemd/system/ark.service"

    echo "Attempting to restart ark service with new parameters..."
    systemctl daemon-reload
    systemctl start ark
    break
  else
    echo "No changes made, quitting out."
    break
  fi
done
