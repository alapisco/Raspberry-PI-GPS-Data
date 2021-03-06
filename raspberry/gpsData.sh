#!/bin/bash


#Gps data file
GPS_DATA_FILE="/home/pi/gps/gpsData"
GPS_SERIAL_INTERFACE="/dev/ttyAMA0"


function NMEAtoDegrees {

coordenate=$1
orientation=$2
mult=1


to=$(echo `expr index "$coordenate" .` -3 |bc)
hours=$(echo $coordenate | cut -c 1-$to)

from=$(echo `expr index "$coordenate" .` -2 |bc)
degrees=$(echo $coordenate | cut -c $from- )


if [[ "$orientation" == "W"  || "$orientation" == "S" ]];then
 mult=-1

fi

 
echo "scale=5; ($hours + $degrees/60) * $mult" | bc -l

}



while read line; do


   
 #Identify type of NMEA sentence
 ID=$(echo $line | awk -F"," '{print $1}' )


 #If a $GPRMC sentence is found
 if [[ $ID == *GPRMC* ]]; then

  #Check number of elements found in the sentence by checking the number of commas found
  COMMAS=$(grep -o "," <<<"$line" | wc -l )

  #If the sentence has 12 commas then it is a valid $GPRMC sentence
  if [ "$COMMAS" -eq 12 ];then
  
  #parse data

  UTC_TIME=$(echo $line | awk -F"," '{print $2}' )
  STATUS=$(echo $line | awk -F"," '{print $3}' )
  LATITUDE=$(echo $line | awk -F"," '{print $4}' )
  NSIndicator=$(echo $line | awk -F"," '{print $5}' )
  LONGITUDE=$(echo $line | awk -F"," '{print $6}' )
  EWIndicator=$(echo $line | awk -F"," '{print $7}' )
  SpeedOverGround=$(echo $line | awk -F"," '{print $8}' )
  CourseOverGround=$(echo $line | awk -F"," '{print $9}' )
  DATE=$(echo $line | awk -F"," '{print $10}' )
  MAGNETIC_VARIATION=$(echo $line | awk -F"," '{print $11}' )
  MODE=$(echo $line | awk -F"," '{print $12}' )
  CHECKSUM=$(echo $line | awk -F"," '{print $13}' )

  if [ ! -z $LATITUDE ];then
   
   LATITUDE_DEG=$(NMEAtoDegrees $LATITUDE $NSIndicator)
   LONGITUDE_DEG=$(NMEAtoDegrees $LONGITUDE $EWIndicator)
   ID_DRIVER="001"
   ID_TRIP="1"
   ON_ROUTE="0"
   COCKPIT_VARIANCE="2.332"

   # Convert UTC date time to our local date time in GDL
   DAY=$(echo $DATE | cut -c 1-2 )
   MONTH=$(echo $DATE | cut -c 3-4 )
   DATE=$(echo "2015-"$MONTH"-"$DAY)

   HH=$(echo $UTC_TIME | cut -c 1-2 )
   MM=$(echo $UTC_TIME | cut -c 3-4 )
   SS=$(echo $UTC_TIME | cut -c 5-6 )
   TIME=$(echo $HH":"$MM":"$SS)

   DATE=$(date -d "$DATE $TIME UTC-5hours" +"%Y-%m-%d")
   TIME=$(date -d "$DATE $TIME UTC-5hours" +"%T")

  echo "$ID_DRIVER,$ID_TRIP,$ON_ROUTE,$DATE,$TIME,$LATITUDE_DEG,$LONGITUDE_DEG,$SpeedOverGround,$CourseOverGround,$MAGNETIC_VARIATION,$COCKPIT_VARIANCE" >> $GPS_DATA_FILE
  fi
  fi
 fi



done < $GPS_SERIAL_INTERFACE
