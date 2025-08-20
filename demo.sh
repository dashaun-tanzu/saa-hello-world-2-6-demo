#!/usr/bin/env bash

DEMO_START=$(date +%s)

TEMP_DIR="upgrade-example"
noClear=""


if [  "$1" == "-H" ] || [ "$1" == "-h" ] || [ "$1" == "--H" ] || [ "$1" == "--h" ] || [ "$1" == "-help" ] || [ "$1" == "--help" ]
	then
		usage
		exit 10
fi		
	
if [ "$1" == "-noClear" ] 
	then
		noClear="Y"
fi		

	
# Load helper functions and set initial variables

returnVal=99
vendir --version &> /dev/null	
returnVal=$?
	
if [ $returnVal -ne 0 ]; then
  echo "vendir not found. Please install vendir first."	
	exit 1
fi

returnVal=99
http --version &> /dev/null	
returnVal=$?
	
if [ $returnVal -ne 0 ]; then
  echo "httpie not found. Please install httpie first."	
	exit 1
fi

vendir sync
. ./vendir/demo-magic/demo-magic.sh
export TYPE_SPEED=100
export DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
PROMPT_TIMEOUT=6


# Stop ANY & ALL Java Process...they could be Springboot running on our ports!
function cleanUp {
	local npid=""

  npid=$(pgrep java)
  
 	if [ "$npid" != "" ] 
		then
  		
  		displayMessage "*** Stopping Any Previous Existing SpringBoot Apps..."		
			
			while [ "$npid" != "" ]
			do
				echo "***KILLING OFF The Following: $npid..."
		  	pei "kill -9 $npid"
				npid=$(pgrep java)
			done  
		
	fi
}

# Function to pause and clear [ or not ] the screen
function talkingPoint() {
  wait

  if [ "$noClear" == "Y" ]; then
    echo ""
    echo "--------------------------------------------------------------------------------------------"
    echo "********************************************************************************************"
    echo "--------------------------------------------------------------------------------------------"
    echo ""
  else
    clear
  fi
}

# Initialize SDKMAN and install required Java versions
function initSDKman() {
  local sdkman_init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
  if [[ -f "$sdkman_init" ]]; then
    source "$sdkman_init"
  else
    echo "SDKMAN not found. Please install SDKMAN first."
    exit 1
  fi
  sdk update
  sdk install java 8.0.462-librca
  sdk install java 24.0.2-graalce
}

# Prepare the working directory
function init {
  rm -rf "$TEMP_DIR"
  mkdir "$TEMP_DIR"
  cd "$TEMP_DIR" || exit
  
	if [ "$noClear" != "Y" ] 
		then
			clear
	fi		
}

# Switch to Java 8 and display version
function useJava8 {
  displayMessage "Use Java 8, this is for educational purposes only, don't do this at home! (I have jokes.)"
  pei "sdk use java 8.0.462-librca"
  pei "java -version"
}

# Switch to Java 24 and display version
function useJava24 {
  displayMessage "Switch to Java 24 for Spring Boot 3"
  pei "sdk use java 24.0.2-graalce"
  pei "java -version"
}

# Create a simple Spring Boot application
function cloneApp {
  displayMessage "Clone a Spring Boot 2.6.0 application"
  pei "git clone https://github.com/dashaun/hello-spring-boot-2-6.git ./"
}

# Start the Spring Boot application
function springBootStart {
  displayMessage "Start the Spring Boot application, Wait For It...."
  pei "./mvnw -q clean package spring-boot:start -DskipTests 2>&1 | tee '$1' &"
}

# Stop the Spring Boot application
function springBootStop {
  displayMessage "Stop the Spring Boot application"
  pei "./mvnw spring-boot:stop -Dspring-boot.stop.fork"
}

# Check the health of the application
function validateApp {
  displayMessage "Check application health"
  pei "while ! http :8080/actuator/health 2>/dev/null; do sleep 1; done"
}

# Display memory usage of the application
function showMemoryUsage {
  local pid=$1
  local log_file=$2
  local rss=$(ps -o rss= "$pid" | tail -n1)
  local mem_usage=$(bc <<< "scale=1; ${rss}/1024")
  echo "The process was using ${mem_usage} megabytes"
  echo "${mem_usage}" >> "$log_file"
}

function advisorBuildConfig {
  displayMessage "Capture some metadata about the application with Advisor"
  pei "advisor build-config get"
}

function showBuildConfig {
  displayMessage "Let's take a look at that config"
  pei "cat target/.advisor/build-config.json"
  echo "^^^ That's the SBOM, Github metadata, and tools with versions!"
}

function advisorUpgradePlanGet {
  displayMessage "How hard could it be to upgrade? Let's get a plan!"
  pei "advisor upgrade-plan get"
}

function advisorUpgradePlanApplySquash {
  displayMessage "Do all the upgrades!"
  pei "advisor upgrade-plan apply --squash 9"
}

# Build a native image of the application
function buildNative {
  displayMessage "Build a native image with AOT"
  pei "./mvnw -Pnative native:compile"
}

# Start the native image
function startNative {
  displayMessage "Start the native image"
  pei "./target/hello-spring 2>&1 | tee nativeWith3.3.log &"
}

# Stop the native image
function stopNative {
  displayMessage "Stop the native image"
  local npid=$(pgrep hello-spring)
  pei "kill -9 $npid"
}

# Display a message with a header
function displayMessage() {
  echo "#### $1"
  echo ""
}

function startupTime() {
  echo "$(sed -nE 's/.* in ([0-9]+\.[0-9]+) seconds.*/\1/p' < $1)"
}

function statsSoFarTableColored {
  displayMessage "Comparison of memory usage and startup times"
  echo ""

  # Define colors
  local WHITE='\033[1;37m'
  local GREEN='\033[1;32m'
  local BLUE='\033[1;34m'
  local YELLOW='\033[1;33m'
  local NC='\033[0m' # No Color

  # Headers (White)
  printf "${WHITE}%-35s %-25s %-15s %s${NC}\n" "Configuration" "Startup Time (seconds)" "(MB) Used" "(MB) Savings"
  echo -e "${WHITE}--------------------------------------------------------------------------------------------${NC}"

  # Spring Boot 2.6 with Java 8 (Yellow - baseline)
  MEM1=$(cat java8with2.6.log2)
  START1=$(startupTime 'java8with2.6.log')
  printf "${RED}%-35s %-25s %-15s %s${NC}\n" "Spring Boot 2.6 with Java 8" "$START1" "$MEM1" "-"

  # Spring Boot 3.3 with Java 23 (Blue - improved)
  MEM2=$(cat java21with3.3.log2)
  PERC2=$(bc <<< "scale=2; 100 - ${MEM2}/${MEM1}*100")
  START2=$(startupTime 'java21with3.3.log')
  PERCSTART2=$(bc <<< "scale=2; 100 - ${START2}/${START1}*100")
  printf "${YELLOW}%-35s %-25s %-15s %s ${NC}\n" "Spring Boot 3.5 with Java 24" "$START2 ($PERCSTART2% faster)" "$MEM2" "$PERC2%"

  # Spring Boot 3.3 with AOT processing, native image (Green - best)
  MEM3=$(cat nativeWith3.3.log2)
  PERC3=$(bc <<< "scale=2; 100 - ${MEM3}/${MEM1}*100")
  START3=$(startupTime 'nativeWith3.3.log')
  PERCSTART3=$(bc <<< "scale=2; 100 - ${START3}/${START1}*100")
  printf "${GREEN}%-35s %-25s %-15s %s ${NC}\n" "Spring Boot 3.5 with AOT, native" "$START3 ($PERCSTART3% faster)" "$MEM3" "$PERC3%"

  echo -e "${WHITE}--------------------------------------------------------------------------------------------${NC}"
  DEMO_STOP=$(date +%s)
  DEMO_ELAPSED=$((DEMO_STOP - DEMO_START))
  echo ""
  echo ""
  echo -e "${WHITE}Demo elapsed time: ${DEMO_ELAPSED} seconds${NC}"
}

# Main execution flow

cleanUp
initSDKman
init
useJava8
talkingPoint
cloneApp
talkingPoint
springBootStart java8with2.6.log
talkingPoint
validateApp
talkingPoint
showMemoryUsage "$(jps | grep 'HelloSpringApplication' | cut -d ' ' -f 1)" java8with2.6.log2
talkingPoint
springBootStop
talkingPoint
advisorBuildConfig
talkingPoint
showBuildConfig
talkingPoint
advisorUpgradePlanGet
talkingPoint
advisorUpgradePlanApplySquash
talkingPoint
useJava24
talkingPoint
springBootStart java21with3.3.log
talkingPoint
validateApp
talkingPoint
showMemoryUsage "$(jps | grep 'HelloSpringApplication' | cut -d ' ' -f 1)" java21with3.3.log2
talkingPoint
springBootStop
talkingPoint
buildNative
talkingPoint
startNative
talkingPoint
validateApp
talkingPoint
showMemoryUsage "$(pgrep hello-spring)" nativeWith3.3.log2
talkingPoint
stopNative
talkingPoint
statsSoFarTableColored
