#!/bin/bash

LOG_FILE=/home/james/git/amarguetix/tests/gps/logs/sendData.log

HISTORY_FOLDER=/home/james/git/amarguetix/tests/gps/history

#tmp directory
tmpDir=/home/james/git/amarguetix/tests/gps/tmp/

# Car identifier
CAR_ID=JHY1636

# Directory where the gps data file is
dataDir=/home/james/git/amarguetix/tests/gps/

# Gps data file
dataFile=gpsData

# server upload url
uploadUrl="http://alapisco.zapto.org/post6.php"

DATE=$(date +'%d%m%y%H%M%S')

echo "Send data started"  | tee -a  $LOG_FILE
date  | tee -a  $LOG_FILE

#Create a tmp directory 
dirName="$CAR_ID"_"$DATE"
mkdir -p $tmpDir/$dirName


#Copy gpsData to a tmp dir
cp $dataDir/$dataFile $tmpDir/$dirName/$DATE
cd $tmpDir

#Empty gpsData
echo "" > $dataDir/$dataFile


#Compressing data file
tarFile=$dirName".tar.gz"
tar -czf $tarFile $dirName

#Delete tmp directory
rm -rf $dirName

#Iterate all tar.gz files 
for tarFile in  *.tar.gz ; do 

echo "Sending file $tarFile"  | tee -a  $LOG_FILE


#Send data file to server
RESPONSE=$(curl --write-out "%{http_code}\n" --silent  -F"operation=upload" -F"fileToUpload=@$tarFile" $uploadUrl | tail -1)
echo "response is $RESPONSE"

if [ $RESPONSE -eq "200" ]; then
  echo "File uploaded"  | tee -a  $LOG_FILE
  echo "Moving file to history directory"  | tee -a  $LOG_FILE
  mv $tarFile $HISTORY_FOLDER
else
  echo "Failed to upload file"  | tee -a  $LOG_FILE
fi


done

