
#! /bin/bash

# Created by Lubos Kuzma
# ISS Program, SADT, SAIT
# August 2022


if [ $# -lt 1 ]; then #if the number of arguments passed is less than one print the following, then exit with an error
	echo "Usage:" 							#the following is the usage of the toolchain
	echo ""
	echo "arm_toolchain.sh  [-p | --port <port number, default 12222>] <assembly filename> [-o | --output <output filename>]"
	echo ""
	echo "-v | --verbose                Show some information about steps performed."
	echo "-g | --gdb                    Run gdb command on executable."
	echo "-b | --break <break point>    Add breakpoint after running gdb. Default is main."
	echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env."
	echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program."
	echo "-p | --port                   Specify a port for communication between QEMU and GDB. Default is 12222."
	echo "-o | --output <filename>      Output filename."
	
	exit 1 #exit with error code 1
fi

POSITIONAL_ARGS=() #create an array for all the arguments that are passed
GDB=False
OUTPUT_FILE=""
VERBOSE=False
QEMU=False
PORT="12222"
BREAK="main"
RUN=False
while [[ $# -gt 0 ]]; do #start a loop for the arguments     ###SHIFT WILL MOVE TO THE NEXT ARGUMENT###
	case $1 in # start a case statement for the first argument 
		-g|--gdb) # if -g or --gdb is in the argument, then set GDB to true
			GDB=True
			shift # past argument 
			;;
		-o|--output)
			OUTPUT_FILE="$2" #if -o or --output is seen, then take the next argument following it as the output file name
			shift # past argument
			shift # past value
			;;
		-v|--verbose) #if -v or --verbose is seen then set verbose to true
			VERBOSE=True
			shift # past argument
			;;
		-q|--qemu) # if -q or --qemu is seen set qemu to true
			QEMU=True
			shift # past argument
			;;
		-r|--run) #if -r or --run is seen set run to true
			RUN=True
			shift # past argument
			;;
		-b|--break) #if -b or --break is seen then set break value to the following argument after -b or --break
			BREAK="$2"
			shift # past argument
			shift # past value
			;;
		-p|--port) #set port to the following argument after -p or --port 
			PORT="$2"
			shift #past argument	
			shift #past value
			;;
		-*|--*)
			echo "Unknown option $1" #input error handling, exit with error code 1 
			exit 1
			;;
		*)
			POSITIONAL_ARGS+=("$1") # save position in array and restart loop
			shift # past argument
			;;
	esac
done #done loop 

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [[ ! -f $1 ]]; then #if the first arg is not a file, print error code 1
	echo "Specified file does not exist"
	exit 1
fi

if [ "$OUTPUT_FILE" == "" ]; then #if output name is empty, use input file name 
	OUTPUT_FILE=${1%.*}
fi

if [ "$VERBOSE" == "True" ]; then #if verbose mode is selected, print the following which will show which flags are selected for each argument 
	echo "Arguments being set:"
	echo "	GDB = ${GDB}"
	echo "	RUN = ${RUN}"
	echo "	BREAK = ${BREAK}"
	echo "	QEMU = ${QEMU}"
	echo "	Input File = $1"
	echo "	Output File = $OUTPUT_FILE"
	echo "	Verbose = $VERBOSE"
	echo "	Port = $PORT" 
	echo ""

	echo "Compiling started..."

fi

# Raspberry Pi 3B ### ARM compiler with flags set for Raspberry Pi 3B
arm-linux-gnueabihf-gcc -ggdb -mfpu=vfp -march=armv6+fp -mabi=aapcs-linux $1 -o $OUTPUT_FILE -static -nostdlib &&


if [ "$VERBOSE" == "True" ]; then #if verbose was set to true, print the following 

	echo "Compiling finished"
	
fi


if [ "$QEMU" == "True" ] && [ "$GDB" == "False" ]; then #if QEMU is set to true and GDB is set to false then do the following 
	# Only run QEMU
	echo "Starting QEMU ..." #print qemu is starting 
	echo "" #new line

	qemu-arm $OUTPUT_FILE && echo "" #execute program with qemu

	exit 0 #exit with 0
	
elif [ "$QEMU" == "False" ] && [ "$GDB" == "True" ]; then #if QEMU is false and GDB is true then do the following 
	# Run QEMU in remote and GDB with remote target on the specified port

	echo "Starting QEMU in Remote Mode listening on port $PORT ..."
	qemu-arm -g $PORT $OUTPUT_FILE &
	
	
	gdb_params=() #create array for gdb arguments
	gdb_params+=(-ex "target remote 127.0.0.1:${PORT}") #set the gdb arguments
	gdb_params+=(-ex "b ${BREAK}") #set the gdb arguments 

	if [ "$RUN" == "True" ]; then #if run is set to true then add the following gdb parameters 

		gdb_params+=(-ex "r")

	fi

	echo "Starting GDB in Remote Mode connecting to QEMU ..." #print that GDB is starting in remote mode and connecting to qemu

	gdb-multiarch "${gdb_params[@]}" $OUTPUT_FILE && #passes gdb-multiarch the specified parameters

	exit 0 #exit with 0

elif [ "$QEMU" == "False" ] && [ "$GDB" == "False" ]; then
	# Don't run either and exit normally

	exit 0

else #error handling for qemu and gdb conflicts 
	echo ""
	echo "****"
	echo "*"
	echo "* You can't use QEMU (-q) and GDB (-g) options at the same time."
	echo "* Defaulting to QEMU only."
	echo "*"
	echo "****"
	echo ""
	echo "Starting QEMU ..."
	echo ""

	qemu-arm $OUTPUT_FILE && echo "" #run output file with qemu
	exit 0 #exit with 0
fi
