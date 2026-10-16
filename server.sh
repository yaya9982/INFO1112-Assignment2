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
        
        if $assign_2_html=$(curl -fsS "https://www.sydney.edu.au/units/INFO1112/2026-S2C-ND-CC")
        then
            echo $assign_2_html | grep -A 2 "Assignment 2"
        else
            echo "usage: error fetching Assignment 2 details"
        fi
        #curl https://www.sydney.edu.au/units/INFO1112/2026-S2C-ND-CC | grep -A 25 "<b>Assignment 2</b>" | grep "<td>3.*</td>" - incase cant type input
        touch assignment.json
        cat > assignment.json <<EOF
        {
            "title" : "Assignment 2",
            "topic" : "Networking",
            "due_date" : "01 Nov 2026 23:59",
            "points" : 15
        }
EOF
    elif [[ "$userinput" == "population" ]]
    then
        if curl -fS -o STE_1.csv "https://dbr.abs.gov.au/processedData/csv/STE_1.csv"
        then
            pop_2025=$(cat STE_1.csv | grep 'Estimated resident population (no.)' | awk -F ',' '{print $NF}')
            echo "Population of 2025 is $pop_2025"
        else
            echo "Usage : CSV installation error"
        fi
        
    fi    
done )&


