#!/usr/bin/env bash

DEMO_START=$(date +%s)

TEMP_DIR="upgrade-example"

# Java version configuration
JAVA8_VERSION="8.0.462-librca"
JAVA25_VERSION="25.r25-nik"

# Function to check if a command exists
check_dependency() {
  local cmd=$1
  local install_msg=$2
  
  if ! command -v "$cmd" &> /dev/null; then
    echo "$cmd not found. $install_msg"
    return 1
  fi
  return 0
}

# Check all required dependencies
check_dependencies() {
  local missing_deps=()
  
  # Check dependencies in parallel by storing results
  check_dependency "vendir" "Please install vendir first." || missing_deps+=("vendir")
  check_dependency "http" "Please install httpie first." || missing_deps+=("httpie")
  check_dependency "bc" "Please install bc first." || missing_deps+=("bc")
  check_dependency "git" "Please install git first." || missing_deps+=("git")
  
  if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "Missing dependencies: ${missing_deps[*]}"
    exit 1
  fi
  
  echo "All dependencies found."
}

# Load helper functions and set initial variables
check_dependencies

vendir sync
. ./vendir/demo-magic/demo-magic.sh
export TYPE_SPEED=100
export DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
export PROMPT_TIMEOUT=6


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

# Function to pause and clear the screen
function talkingPoint() {
  wait
  clear
}

# Check if Java version is already installed
check_java_installed() {
  local version=$1
  sdk list java | grep -q "$version" && sdk list java | grep "$version" | grep -q "installed"
}

# Initialize SDKMAN and install required Java versions
function initSDKman() {
  local sdkman_init
  sdkman_init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
  if [[ -f "$sdkman_init" ]]; then
    # shellcheck disable=SC1090
    source "$sdkman_init"
  else
    echo "SDKMAN not found. Please install SDKMAN first."
    exit 1
  fi
  
  echo "Updating SDKMAN..."
  sdk update
  
  # Install Java versions only if not already installed
  if ! check_java_installed "$JAVA8_VERSION"; then
    echo "Installing Java $JAVA8_VERSION..."
    sdk install java "$JAVA8_VERSION"
  else
    echo "Java $JAVA8_VERSION already installed."
  fi
  
  if ! check_java_installed "$JAVA25_VERSION"; then
    echo "Installing Java $JAVA25_VERSION..."
    sdk install java "$JAVA25_VERSION"
  else
    echo "Java $JAVA25_VERSION already installed."
  fi
}

# Prepare the working directory
function init {
  rm -rf "$TEMP_DIR"
  mkdir "$TEMP_DIR"
  cd "$TEMP_DIR" || exit
  clear
}

# Switch to Java 8 and display version
function useJava8 {
  displayMessage "Use Java 8, this is for educational purposes only, don't do this at home! (I have jokes.)"
  pei "sdk use java $JAVA8_VERSION"
  pei "java -version"
}

# Switch to Java 24 and display version
function useJava24 {
  displayMessage "Switch to Java 24 for Spring Boot 3"
  pei "sdk use java $JAVA25_VERSION"
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
  local rss
  rss=$(ps -o rss= "$pid" | tail -n1)
  local mem_usage
  mem_usage=$(bc <<< "scale=1; ${rss}/1024")
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
  local npid
  npid=$(pgrep hello-spring)
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
  printf "${YELLOW}%-35s %-25s %-15s %s ${NC}\n" "Spring Boot 3.5 with Java 25" "$START2 ($PERCSTART2% faster)" "$MEM2" "$PERC2%"

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
  echo -e "${BLUE}Demo elapsed time: ${DEMO_ELAPSED} seconds${NC}"
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
