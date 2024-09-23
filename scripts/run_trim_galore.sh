#! /bin/bash
#--------------------------------------------------------------------------------------------------------------
# Function definitions
# Usage function
function display_help {
        echo "Author: A. Drakaki"
        echo ""
        echo "Script to submit read trimming job with Trim Galore! to a High Performance Cluster. All fastq files of the given directory will be trimmed."
        echo ""
        echo "IMPORTANT: Make sure cutadapt, FastQC, and GNU parallel are available in your system."
        echo ""
        echo "Usage: $0 -e <EXPERIMENT_DIR> -s <SEQ> -d <TRIM STEP OPTIONS TO CHANGE DEFAULT OR ADD TO IT> -o <OUTDIR> -p <NUMBER OF JOBS TO RUN SIMULTANEOUSLY>"
        echo ""
        echo "  -e <EXPDIR>:                    Directory with fastq files (will also serve as output directory)"
        echo ""
        echo "  -s <SEQ_TECH>:                  Can be either paired or single. If paired, then Trim Galore! will run with option --paired"
        echo ""
        echo "  -d <EXTRAs>:                    Extra options for Trim Galore! (Please provide all of them between two quotation marks)"
        echo ""
        echo "                                  For example: --quality: trim low quality reads based on Phred score."
        echo "                          It's important to specify which adapters you would like to use within this option."
        echo "                          If \"--illumina\" is specified, the sequence to be trimmed is the first 13bp of the Illumina universal adapter."
        echo "                          You can also use \"--adapter\" to specify a custom sequence."
        echo "                          Please refer to Trim Galore! manual to adjust parameters to your needs."
        echo ""
        echo "  -o <OUTDIR>:                    All output files will be written to this directory."
        echo ""
        echo "  -p <GNU parallel commands>      This script will run trimming jobs in parallel using \"-j\" and \"--xapply\". Specify the number of jobs to run at the same time (-j) here."
        echo "                                          Include any other parallel command options here, between two quotation marks."
        echo ""
        echo "  -h :                            Print this help message"
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
SEQ=""
EXTRA=""
OUTDIR=""
PARALLEL=""

#--------------------------------------------------------------------------------------------------------------
# Define options

while getopts "e:s:d:o:p:h" opt; do
  case $opt in
        e)
                EXPDIR=$OPTARG
                ;;
        s)
                SEQ=$OPTARG
                ;;
        d)
                EXTRA=$OPTARG
                ;;
        o)
                OUTDIR=$OPTARG
                ;;
        p)
                PARALLEL=$OPTARG
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


# check tool availability

which cutadapt > /dev/null || { echo "cutadapt was not found in your system's PATH, exiting..."; exit 1; }
which trim_galore > /dev/null || { echo "cutadapt was not found in your system's PATH, exiting..."; exit 1; }
## make sure you also have: fastqc and parallel

# Set max job time
MAXTIME=24:00:00

# path to job script
JOB="path/to/run_trim_galore.job"

# time of submission
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")


# submit
sbatch --mincpus=8 --time=$MAXTIME --export=ALL,EXPDIR=$EXPDIR,SEQ=$SEQ,EXTRA="$EXTRA",PARALLEL="$PARALLEL",OUTDIR=$OUTDIR $JOB
