#! /bin/bash
#--------------------------------------------------------------------------------------------------------------
# Function definitions
# Usage function
function display_help {
        echo "Author: A. Drakaki"
        echo ""
        echo "Script to submit read alignment job to a HPC."
        echo ""
        echo "Usage: $0 -e <EXPERIMENT_DIR> -i <HT2_INDEX> -s <SEQ> -p <THREADS> -d <EXTRAs> -u <UNPAIRED>"
        echo ""
        echo "  -e <EXPDIR>:          Directory with fastq files (will also serve as output directory)"
        echo ""
        echo "  -i <HT2_IDX>:           Directory where indexed genome files can be found"
        echo ""
        echo "  -s <SEQ_TECH>:          Can be either paired or single"
        echo ""
        echo "  -p <THREADS>:   Number of threads to pass on to the -p option of Trimmomatic"
        echo ""
        echo "  -d <EXTRAs>:          Extra options for hisat2 (Please provide all of them between two quotation marks)"
        echo ""
        echo "  -u <UNPAIRED>:  Option to keep unpaired reads that align at least once (YES/NO) (will be passed to --al-gz, unpaired and unaligned reads will be passed to --un-gz)"
        echo "                                  Keep in mind: this script looks for fastq files with \"trimmed\" written in their basename to run HISAT2."
        echo "                                  If you have specified YES here (-u), the script will replace \"trimmed\" with \"unpaired\", so make sure these files, "
        echo "                                  which are usually obtained following a read trimming job of paired-end reads, also exist in your EXPDIR"
        echo ""
        echo "  -h:                     Print this help message"
        echo ""
        echo "NOTE: By default, the following options will be included when running hisat2: --mm --add-chrname --new-summary --no-spliced-alignment"
        echo "NOTE: Will also use samtools to convert SAM output files to BAM"
        echo ""
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
INDEX=""
SEQ=""
EXTRA=""
UNPAIRED=""
MYTHREADS=""

#--------------------------------------------------------------------------------------------------------------
# Define options

while getopts "e:s:i:d:u:p:h" opt; do
  case $opt in
        e)
                EXPDIR=$OPTARG
                ;;
        i)
                INDEX=$OPTARG
                ;;
        s)
                SEQ=$OPTARG
                ;;
        d)
                EXTRA=$OPTARG
                ;;
        p)
                MYTHREADS=$OPTARG
                ;;
        u)
                UNPAIRED=$OPTARG
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
## index
if [ -z "$INDEX" ]; then
        echo "You have not provided any directory containing the genome index, exiting"
        exit 1
fi
## unpaired
if [ -z  "$UNPAIRED" ]; then
        echo "You have not clarified whether unpaired reads should be separately stored, default to NO"
        UNPAIRED="NO"
        echo "Keep unpaired reads? $UNPAIRED"
fi

# load modules
which samtools > /dev/null || { echo "Samtools was not found in your system's PATH, exiting..."; exit 1; }

which hisat2 > /dev/null || { echo "HISAT2 was not found in your system's PATH, exiting..."; exit 1; }

# Set max job time
MAXTIME=24:00:00

# path to job script
JOB="/path/to/map_with_hisat2.job"

# time of submission
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# submit
sbatch --mincpus=$MYTHREADS --time=$MAXTIME --export=ALL,EXPDIR=$EXPDIR,SEQ=$SEQ,INDEX=$INDEX,UNPAIRED=$UNPAIRED,EXTRA="$EXTRA",MYTHREADS=$MYTHREADS, $JOB
