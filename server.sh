#!/bin/bash
ip=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')
port=$(ss -ltn)
echo "The server is running at $ip xxxx "
echo ".................."
( while true
    do 
    userinput=$(nc -l -v 1234) 
    if [[ "$userinput" == "assignment" ]]
    then 
        echo ass1
    elif [[ "$userinput" == "population" ]]
    then
        echo pop1
    fi    
done )&

