#!/bin/bash
#SBATCH --job-name=stringfinder
#SBATCH --output=./result/stringfinder_%A_%a.out
#SBATCH --error=./result/stringfinder_%A_%a.err
#SBATCH --array=1-4
#SBATCH --time=00:05:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G

# Create necessary directories
mkdir -p ./bin ./result ./script

# Check if source file exists
if [ ! -f "./src/StringFinder.java" ]; then
    echo "Error: Source file ./src/StringFinder.java not found"
    exit 1
fi

# Set run ID with zero padding
RUN_ID=$(printf "%02d" $SLURM_ARRAY_TASK_ID)

echo "Starting StringFinder job - Array Task ID: $SLURM_ARRAY_TASK_ID, Run ID: $RUN_ID"
echo "Node: $(hostname)"
echo "Date: $(date)"

# Compile Java code
echo "Compiling Java code for run $RUN_ID..."
javac -d ./bin ./src/StringFinder.java
if [ $? -ne 0 ]; then
    echo "Error: Compilation failed for run $RUN_ID"
    exit 1
fi

echo "Compilation successful for run $RUN_ID"

# Run the program with run ID
echo "Starting execution for run $RUN_ID..."
java -cp ./bin -Drun.id=$RUN_ID StringFinder

# Check if required output files were created
if [ ! -f "./result/evaluate_${RUN_ID}.csv" ]; then
    echo "Error: evaluate_${RUN_ID}.csv not created"
    exit 1
fi

echo "Successfully completed run $RUN_ID"
echo "Output files:"
ls -la ./result/evaluate_${RUN_ID}.csv
echo "End time: $(date)"