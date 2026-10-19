#!/bin/bash
echo "v9"
# ask abt ss -ltn for port, since ss -ltn needs server running to work, but server not opened? chicken egg problem
# ip=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')
# port=$(ss -ltn | grep '\*:\*' | awk '{print $4}'| awk -F ':' '{print $2}')
# echo "The server is running at $ip, port=$port"
# echo ".................."
output_to_user=/tmp/reply
rm -f "$output_to_user"
mkfifo "$output_to_user"
( while true
    do 
    nc -l -v 1234 < "$output_to_user" | {
        read -r userinput

        if [[ "$userinput" == "assignment" ]]
        then 
            
            if assign_2_html=$(curl -fsS "https://www.sydney.edu.au/units/INFO1112/2026-S2C-ND-CC")
            then
                echo $assign_2_html | grep -A 2 "Assignment 2" | html2text
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
done )&

# ip=$(ifconfig eth0 | grep 'inet ' | awk '{print $2}')
# port=$(ss -ltn | grep '\*:\*' | awk '{print $4}'| awk -F ':' '{print $2}')
# echo "The server is running at $ip, port=$port"
# echo ".................."
