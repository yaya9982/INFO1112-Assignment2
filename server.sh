#!/bin/bash

#TO DO:
# git logs
# 2 test cases 
# ip addr and port problem
# ask abt ss -ltn for port, since ss -ltn needs server running to work, but server not opened? chicken egg problem

output_to_user=/tmp/reply
rm -f "$output_to_user"
mkfifo "$output_to_user"
start=1
( while true
    do 
    nc -l -v 1234 < "$output_to_user" | {
        if [ $start -ne 0 ]
        then
            sleep 1
            ip=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}') 
            port=$(ss -ltn | grep '0.0.0.0:' | awk '{print $4}'| awk -F ':' 'NR==1 {print $2}')
            echo "The server is running at $ip, port=$port" >&2
            echo ".................." >&2 
            start=0
        fi
        read -r userinput

        if [[ "$userinput" == "assignment" ]]
        then 
            
            if assign_2_output=$(curl -fsS "https://www.sydney.edu.au/units/INFO1112/2026-S2C-ND-CC" | html2text | grep -A 2 "Assignment 2")
            then
                echo $assign_2_output
                touch assignment.json
                title=$( echo "$assign_2_output" | awk 'NR==1' | awk '{print $1 " " $2}')
                topic=$( echo "$assign_2_output" | awk 'NR==3' | awk '{print $1}')
                date_pt_1=$( echo "$assign_2_output" | awk 'NR==1' | awk '{print $5}')
                date_pt_2=$( echo "$assign_2_output" | awk 'NR==2' | awk '{print $7 " " $8 " " $10}')
                date_pt_3=$( echo "$assign_2_output" | awk 'NR==3' | awk '{print $2}')
                due_date="$date_pt_1 $date_pt_2$date_pt_3"
                points=$( echo "$assign_2_output" | awk 'NR==2' | awk '{print $6}' | grep -o '[0-9]*')
                cat > assignment.json <<EOF
                {
                    "title" : "$title",
                    "topic" : "$topic",
                    "due_date" : "$due_date",
                    "points" : "$points"
                }
EOF
                cat assignment.json
            else
                echo "usage: error fetching Assignment 2 details"
            fi
            

        elif [[ "$userinput" == "population" ]]
        then
            if curl -fsS -o STE_1.csv "https://dbr.abs.gov.au/processedData/csv/STE_1.csv"
            then
                pop_2025=$(cat STE_1.csv | grep 'Estimated resident population (no.)' | awk -F ',' '{print $NF}')
                echo "Population of 2025 is $pop_2025" >&2
                # single arrow to overwrite to csv file
                cat STE_1.csv | grep 'Description' | awk -F ',' -v OFS=',' '{print $(NF-5), $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' > plot.csv
                cat STE_1.csv | grep 'Estimated resident population (no.)' | awk -F ',' -v OFS=',' '{print $(NF-5), $(NF-4), $(NF-3), $(NF-2), $(NF-1), $NF}' >> plot.csv
                if python3 plot_graph.py plot.csv population_graph.png
                then
                    cat population_graph.png
                else
                    echo "Usage : error generating population graph"
                fi
            else
                echo "Usage : CSV installation error"
            fi
            
        else
            
            if [[ $userinput =~ ^[[:space:]]*-?[0-9]+\.?[0-9]+,[[:space:]]*-?[0-9]+\.?[0-9]+[[:space:]]*$ ]]
            then
                # if input are coords
                coords=$(echo "$userinput" | tr -d ' \r')
                poi_request=$(curl -s -G \
                --data-urlencode "geometry=$coords" \
                --data-urlencode "geometryType=esriGeometryPoint" \
                --data-urlencode "inSR=4326" \
                --data-urlencode "distance=1000" \
                --data-urlencode "units=esriSRUnit_Meter" \
                --data-urlencode "outFields=*" \
                --data-urlencode "f=json" \
                "https://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_POI/MapServer/0/query")
                status=$?
                poi_request=$( echo $poi_request | jq -c '[.features[].attributes.poiname // empty]')
                echo "---------"
                if [ "$status" -ne 0 ]
                then
                    echo "Usage : error fetching POI data from coords"
                else
                    # returns list of pois in neighborhood
                    echo "$poi_request" > "poi_output.json"
                    cat poi_output.json
                fi
            else
                poi_request=$(curl -s -G \
                --data-urlencode "where=poiname='$userinput'" \
                --data-urlencode "outFields=*" \
                --data-urlencode "returnGeometry=true" \
                --data-urlencode "f=json" \
                "https://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_POI/MapServer/0/query")
                status=$?
                if [[ $(echo "$poi_request" | jq '.features') != "[]" ]]
                then
                    # userinput is a valid poi so fetch the coords
                    lat=$( echo "$poi_request" | jq '.features[0].geometry.y')
                    long=$(echo "$poi_request" | jq '.features[0].geometry.x')
                    poi_request=$(curl -s -G \
                    --data-urlencode "geometry=$long,$lat" \
                    --data-urlencode "geometryType=esriGeometryPoint" \
                    --data-urlencode "inSR=4326" \
                    --data-urlencode "distance=1000" \
                    --data-urlencode "units=esriSRUnit_Meter" \
                    --data-urlencode "outFields=*" \
                    --data-urlencode "f=json" \
                    "https://maps.six.nsw.gov.au/arcgis/rest/services/public/NSW_POI/MapServer/0/query")
                    status=$?
                    # fetches pois and puts into list then into json file
                    poi_request=$( echo $poi_request | jq -c '[.features[].attributes.poiname // empty]')
                    if [ "$status" -ne 0 ]
                    then
                        echo "Usage : error fetching POI data"
                    else
                        echo $poi_request > "poi_output.json"
                        cat poi_output.json
                    fi
                fi
            fi
        fi
    } > "$output_to_user"
    server_status=${PIPESTATUS[0]}
    if [ "$server_status" -ne 0 ]
    then
        echo "usage : server not running"
    fi
done )&

# ip=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')
# port=$(ss -ltn | grep '\*:\*' | awk '{print $4}'| awk -F ':' '{print $2}')
# echo "The server is running at $ip, port=$port"
# echo ".................."
