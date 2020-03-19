#!/bin/bash

# Options
while getopts u:p:h:d: OPT
do
  case $OPT in
    "u" ) ZUSER="${OPTARG}";;
    "p" ) ZPASSWD="${OPTARG}";;
    "h" ) ZHOST="${OPTARG}";;
    "d" ) DAY_AGO="${OPTARG}";;
    * ) echo "Invalid option: ${OPTARG}" && exit 99;;
  esac
done

# Preprocessing
expr ${DAY_AGO} + 1 1>&/dev/null
RC=${?}
[[ ${RC} != 0 ]] || [[ ${DAY_AGO} < 0 ]] && echo "Option /'d/' must be integer greater than or equal to 0." && exit 99

if [[ ${DAY_AGO} = 0 ]]; then
  TIME_TILL_UNIX=$(date +%s)
else
  TIME_TILL_UNIX=$(date +%s --date "${DAY_AGO} day ago")
fi

# Zabbix API header
HEADER="Content-Type: application/json-rpc"
APIURL="https://${ZHOST}/zabbix/api_jsonrpc.php"

# Get a authentification code of Zabbix User
AUTH=$(curl -sS -k -X POST -d '{
  "jsonrpc": "2.0",
  "method": "user.login",
  "params": {
    "user": "'${ZUSER}'",
    "password": "'${ZPASSWD}'"
  },
  "id": 1,
  "auth": null
}' -H "${HEADER}" ${APIURL} | grep -o -P '\w{32}')


# Get trigger enabled manual close
OBJECTID_ARRAY=($(curl -sS -k -X POST -d '{
  "jsonrpc": "2.0",
  "method": "trigger.get",
  "params": {
    "output": [
      "triggerid"
    ],
    "filter": {
      "value": 1,
      "manual_close": 1
    },
    "sortfield": "triggerid"
  },
  "auth": "'${AUTH}'",
  "id": 2
}' -H "${HEADER}" ${APIURL} | python -m json.tool | awk '/triggerid/ {print $NF}'))

[[ ${#OBJECTID_ARRAY[*]} = 0 ]] && echo "Not exist the trigger enabled manual close." && exit 0

OBJECTID_LIST=$(echo [${OBJECTID_ARRAY[@]}] | sed 's/ /,/g')


# Get event IDs matched the conditions
EVENTID_ARRAY=($(curl -sS -k -X POST -d '{
  "jsonrpc": "2.0",
  "method": "problem.get",
  "params": {
    "output": [
      "eventid",
      "objectid"
    ],
    "filter": {
      "acknowledged": "0",
      "objectid": '${OBJECTID_LIST}'
    },
    "time_till": '${TIME_TILL_UNIX}',
    "sortfield": "eventid",
    "sortorder": "DESC"
  },
  "auth": "'${AUTH}'",
  "id": 3
}' -H "${HEADER}" ${APIURL} | python -m json.tool | awk '/eventid/ {print $NF}' | sed 's/,//g'))

[[ ${#EVENTID_ARRAY[*]} = 0 ]] && echo "Not exist the target ploblems." && exit 0

EVENTID_LIST=$(echo [${EVENTID_ARRAY[@]}] | sed 's/ /,/g')

# Close the problems
curl -sS -k -X POST -d '{
  "jsonrpc": "2.0",
  "method": "event.acknowledge",
  "params": {
    "eventids": '${EVENTID_LIST}',
    "action": 7,
    "message": "Problem closed by script"
  },
  "auth": "'${AUTH}'",
  "id": 4
}' -H "${HEADER}" ${APIURL}

# Logout from Zabbix
curl -sS -k -X POST -d '{
  "jsonrpc": "2.0",
  "method": "user.logout",
  "params": [],
  "auth": "'${AUTH}'",
  "id": 5
}' -H "${HEADER}" ${APIURL}

echo "Problems closed successfully."
exit 0
