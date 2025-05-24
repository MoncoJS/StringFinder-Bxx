#!/bin/bash

# Create necessary directories
mkdir -p ./result
mkdir -p ./bin

# Compile Java code
echo "Compiling Java code..."
javac -d ./bin ./src/StringFinder.java

# Run the SLURM job
echo "Submitting SLURM job..."
sbatch ./script/run.sh

# Wait for job to complete (5 minutes + buffer)
echo "Waiting for job to complete..."
sleep 320

# Check if all CSV files are generated
echo "Checking result files..."
for i in {01..04}; do
    if [ ! -f "./result/evaluate_$i.csv" ]; then
        echo "Error: evaluate_$i.csv not found"
        exit 1
    fi
done

# Generate plots for each task
echo "Generating plots..."
for i in {1..4}; do
    Rscript ./script/plot.R $i
done

echo "Process completed successfully!"