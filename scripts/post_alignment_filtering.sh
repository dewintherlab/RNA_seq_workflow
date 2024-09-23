#! /bin/bash
#--------------------------------------------------------------------------------------------------------------
# Function definitions
# Usage function
function display_help {
        echo "Author: A. Drakaki"
        echo ""
        echo "Script to send post-alignement filtering job for RNA-seq to a HPC. The operation includes: indexing, removing secondary and"
        echo "supplementary alignments, as well as alignments with a MAPQ value lower than 20, collating, fixing mate information and"
        echo "sorting. Tools used: samtools."
        echo ""
        echo "Usage: $0 -b <BAMDIR> -o <OUTDIR> -t <THREADS TO USE WITH SAMTOOLS>"
        echo ""
        echo "  -b <BAMDIR>:            Directory with BAM files containing mapped reads"
        echo ""
        echo "  -o <OUTDIR>:            Directory to write filtered BAM files to"
        echo ""
        echo "  -t <THREADS>:           Number of threads to use for samtools -@"
        echo ""
        echo "  -h:                   Print this help message"
        echo ""
        exit 1
}

#--------------------------------------------------------------------------------------------------------------
# Display help and exit if not enough arguments

if [ $#  -lt 1 ]
then
        display_help
fi

# Initialize variab;es

BAMDIR=""
OUTDIR=""
THREADS=""

#--------------------------------------------------------------------------------------------------------------
# Parse flags

while getopts "b:o:t:h" opt; do
  case $opt in
        b)
                BAMDIR=$OPTARG
                ;;
        o)
                OUTDIR=$OPTARG
                ;;
        t)
                THREADS=$OPTARG
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

# Check if tools are present in the system
which samtools > /dev/null || { echo "Samtools was not found in your system's PATH, exiting..."; exit 1; }

which picard.jar > /dev/null || { echo "The Picard jarfile was not found in your system's PATH, exiting..."; exit 1; }

# check for Java

# Set some boundaries

if [ -z "$BAMDIR" ]; then
        echo "No input BAM directory (-b) given, exiting"
        exit 1
fi

if [ -z "$OUTDIR" ]; then
        echo "No out directory (-o) given, exiting"
        exit 1
fi


if [ -z "$THREADS" ]; then
        echo "You did not choose a desired number of threads, default to 6"
        THREADS=6
fi

# Check if OUTDIR exists

if [ -d "$OUTDIR" ]; then
        echo "Filtered reads will be written to: $OUTDIR"
else
        mkdir "$OUTDIR"
        echo "Filtered reads will be written to: $OUTDIR"
fi

# Set max job time
MAXTIME=24:00:00

# path to job script
JOB="/path/to/post_alignment_filtering.job"

# time of submission
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# submit
sbatch --mincpus=$THREADS --time=$MAXTIME --export=ALL,BAMDIR=$BAMDIR,OUTDIR=$OUTDIR,THREADS=$THREADS $JOB
