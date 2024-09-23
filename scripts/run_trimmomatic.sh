#! /bin/bash
#--------------------------------------------------------------------------------------------------------------
# Function definitions
# Usage function
function display_help {
        echo "Author: A. Drakaki"
        echo ""
        echo "Script to submit read trimming job to a HPC. All fastq files of the given directory will be trimmed."
        echo ""
        echo "Usage: $0 -e <EXPERIMENT_DIR> -a <ADAPTERS> -s <SEQ> -d <TRIM STEP OPTIONS TO CHANGE DEFAULT OR ADD TO IT>"
        echo ""
        echo "  -e <EXPDIR>:            Directory with fastq files (will also serve as output directory)"
        echo ""
        echo "  -a <ADAPTERS>:  Name of adapter fasta file, for example TrueSeq3-PE.fa (options can be found at /path/to/Trimmomatic/adapters)"
        echo ""
        echo "  -s <SEQ_TECH>:  Can be either paired or single"
        echo ""
        echo "  -d <EXTRAs>:            Extra options for Trimmomatic (Please provide all of them between two quotation marks)"
        echo "                  The script will run with a set of default Trimmomatic step options (see below). If you want to add more, use this option"
        echo ""
        echo "  -m <MEMORY>:            Memory allocated to Java"
        echo ""
        echo "  -i <INITIAL_HEAP_SIZE>: Initial heap size allocated to Java"
        echo ""
        echo "  -h:                     Print this help message"
        echo ""
        echo "Default parameters used: LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36"
        echo "This job is meant to work with  Trimmomatic-0.39, for future releases you can modify its content"
        exit 1
}

#--------------------------------------------------------------------------------------------------------------
# Display help and exit if not enough arguments

if [ $#  -lt 1 ]
then
        display_help
fi

# Initialize variables

EXPDIR=""
ADAPTERS=""
SEQ=""
EXTRA=""
MEM=""
HEAPSIZE=""

#--------------------------------------------------------------------------------------------------------------
# Define options

while getopts "e:a:s:f:m:i:h" opt; do
  case $opt in
        e)
                EXPDIR=$OPTARG
                ;;
        a)
                ADAPTERS=$OPTARG
                ;;
        s)
                SEQ=$OPTARG
                ;;
        e)
                EXTRA=$OPTARG
                ;;
        m)
                MEM=$OPTARG
                ;;
        i)
                HEAPSIZE=$OPTARG
                ;;
        h)
                display_help
                ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
          ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
  esac
done

# Set exit status for required options
## expdir
if [ -z "$EXPDIR" ]; then
        echo "You have not provided any directory with fastq files, exiting"
        exit 1
fi
## seq
if [ -z "$SEQ" ]; then
        echo "You have not clarified if you have single- or paired- end reads, exiting"
        exit 1
fi
## adapters
if [ -z "$ADAPTERS" ] && [ "$SEQ" == "paired" ]; then
        echo "You have not specified the name of the adapters to be used. Will use TrueSeq3-PE.fa"
fi

if [ -z "$ADAPTERS" ] && [ "$SEQ" == "single" ]; then
        echo "You have not specified the name of the adapters to be used. Will use TrueSeq3-SE.fa"
fi

# load java
# ....

# Set max job time
MAXTIME=24:00:00

# path to job script
JOB="/path/to/run_trimmomatic.job"

# time of submission
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")


# submit
sbatch --mincpus=8 --time=$MAXTIME --export=ALL,EXPDIR=$EXPDIR,SEQ=$SEQ,ADAPTERS=$ADAPTERS,MEM=$MEM,HEAPSIZE=$HEAPSIZE,EXTRA="$EXTRA",THREADS=8 $JOB
