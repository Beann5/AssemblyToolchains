#! /bin/bash

# Created by Lubos Kuzma
# ISS Program, SADT, SAIT
# August 2022


if [ $# -lt 1 ]; then # check  if number of arguments is less than 1 print the following
	echo "Usage:" #print usage instructions
	echo "" #print newline
	echo "x86_toolchain.sh [ options ] <assembly filename> [-o | --output <output filename>]" #how to use toolchain
	echo "" #new line
	echo "-v | --verbose                Show some information about steps performed." #print verbose option explanation
	echo "-g | --gdb                    Run gdb command on executable." #print gdb option explanation
	echo "-b | --break <break point>    Add breakpoint after running gdb. Default is _start." #print break option explanation
	echo "-r | --run                    Run program in gdb automatically. Same as run command inside gdb env." #print run option explanation
	echo "-q | --qemu                   Run executable in QEMU emulator. This will execute the program." #print qemu option explanation
	echo "-64| --x86-64                 Compile for 64bit (x86-64) system." #print -x86 option explanation 
	echo "-o | --output <filename>      Output filename." #print output option explanation

	exit 1 #exit with 1 
fi

POSITIONAL_ARGS=() #create an array to store arguments passed to script
GDB=False #track if gdb option  was provided
OUTPUT_FILE="" #var storing name of output file
VERBOSE=False #track if verbose optiion was provided
BITS=False #track if compiling for 64 bit architecture
QEMU=False #track if qemu option was provided 
BREAK="_start" #default breakpoint for gdb
RUN=False #default option for if the exe should be run right away

while [[ $# -gt 0 ]]; do
	case $1 in
		-g|--gdb) #if -g or --gdb is seen in the argument set GDB to true
			GDB=True
			shift # past argument
			;;
		-o|--output)
			OUTPUT_FILE="$2" #second argument following is set as the output file name
			shift # past argument
			shift # past value
			;;
		-v|--verbose) #if -v or --verbose is in the argument, set verbose to true
			VERBOSE=True
			shift # past argument
			;;
		-64|--x84-64) #if -64 or --x84-64 is in the argument, set the BITS option to true
			BITS=True
			shift # past argument
			;;
		-q|--qemu) #if qemu is in argument, set qemu option to true
			QEMU=True 
			shift # past argument
			;;
		-r|--run) #if run is in argument, set run option to true
			RUN=True
			shift # past argument
			;;
		-b|--break) #if break is in argument, set break option to second argument following -b or --break
			BREAK="$2"
			shift # past argument
			shift # past value
			;;
		-*|--*)
			echo "Unknown option $1" #handle user input error
			exit 1 #error exit
			;;
		*)
			POSITIONAL_ARGS+=("$1") # save positional arg
			shift # past argument
			;;
	esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [[ ! -f $1 ]]; then #check the input file still exists
	echo "Specified file does not exist"
	exit 1
fi

if [ "$OUTPUT_FILE" == "" ]; then #if no output file is set, use input files name
	OUTPUT_FILE=${1%.*}
fi

if [ "$VERBOSE" == "True" ]; then #if verbose option is selected, print what the value of each option is
	echo "Arguments being set:"
	echo "	GDB = ${GDB}"
	echo "	RUN = ${RUN}"
	echo "	BREAK = ${BREAK}"
	echo "	QEMU = ${QEMU}"
	echo "	Input File = $1"
	echo "	Output File = $OUTPUT_FILE"
	echo "	Verbose = $VERBOSE"
	echo "	64 bit mode = $BITS" 
	echo ""

	echo "NASM started..."

fi

if [ "$BITS" == "True" ]; then #if bits is true run the command line argument to execute nasm for x64 archi

	nasm -f elf64 $1 -o $OUTPUT_FILE.o && echo ""


elif [ "$BITS" == "False" ]; then #else run the command line argument to execute nasm for x32 archi

	nasm -f elf $1 -o $OUTPUT_FILE.o && echo ""

fi

if [ "$VERBOSE" == "True" ]; then #if verbose mode is true, print to the terminal the following 

	echo "NASM finished"
	echo "Linking ..."
	
fi

if [ "$VERBOSE" == "True" ]; then #not sure of the purpose of this being doubled

	echo "NASM finished"
	echo "Linking ..."
fi

if [ "$BITS" == "True" ]; then #if bits is true run the command line argument to execute nasm for x64 archi

	ld -m elf_x86_64 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""


elif [ "$BITS" == "False" ]; then #else run the command line argument to execute nasm for x32 archi

	ld -m elf_i386 $OUTPUT_FILE.o -o $OUTPUT_FILE && echo ""

fi


if [ "$VERBOSE" == "True" ]; then #print linking is finished 

	echo "Linking finished"

fi

if [ "$QEMU" == "True" ]; then #if qemu == true then start quemu using the BITS option to specifiy x64 or x32

	echo "Starting QEMU ..."
	echo ""

	if [ "$BITS" == "True" ]; then # qemu option of x86-x64
	
		qemu-x86_64 $OUTPUT_FILE && echo ""

	elif [ "$BITS" == "False" ]; then #qemu option for x32

		qemu-i386 $OUTPUT_FILE && echo ""

	fi

	exit 0
	
fi

if [ "$GDB" == "True" ]; then #if gdb is selected do the following

	gdb_params=()
	gdb_params+=(-ex "b ${BREAK}") #add breakpoint parameter to argument 

	if [ "$RUN" == "True" ]; then #add run aparmetere to argument 
		gdb_params+=(-ex "r")

	fi

	gdb "${gdb_params[@]}" $OUTPUT_FILE #start gdb with specified paramters above

fi
