#!/bin/bash

# Submit and monitor StringFinder jobs
echo "=== StringFinder Job Submission Script ==="
echo "Starting at: $(date)"

# Create necessary directories
mkdir -p ./bin ./result ./script

# Check if source files exist
if [ ! -f "./src/StringFinder.java" ]; then
    echo "Error: Source file ./src/StringFinder.java not found"
    echo "Please ensure the Java source file is in the ./src/ directory"
    exit 1
fi

# Copy scripts to script directory for organization
if [ -f "./run_stringfinder.sh" ]; then
    cp ./run_stringfinder.sh ./script/
    echo "Copied run_stringfinder.sh to ./script/"
fi

if [ -f "./plot_results.R" ]; then
    cp ./plot_results.R ./script/
    echo "Copied plot_results.R to ./script/"
fi

# Clean previous results
echo "Cleaning previous results..."
rm -f ./result/evaluate_*.csv
rm -f ./result/plot_*.pdf
rm -f ./result/time.txt
rm -f ./result/stringfinder_*.out
rm -f ./result/stringfinder_*.err

# Submit the SLURM job
echo ""
echo "Submitting SLURM job array (4 tasks)..."
if [ -f "./script/run_stringfinder.sh" ]; then
    SLURM_SCRIPT="./script/run_stringfinder.sh"
else
    SLURM_SCRIPT="./run_stringfinder.sh"
fi

# Make script executable
chmod +x $SLURM_SCRIPT

# Submit job and capture job ID
JOB_ID=$(sbatch --parsable $SLURM_SCRIPT)

if [ $? -eq 0 ]; then
    echo "Job submitted successfully with ID: $JOB_ID"
    echo "Array tasks: ${JOB_ID}_1, ${JOB_ID}_2, ${JOB_ID}_3, ${JOB_ID}_4"
else
    echo "Error: Failed to submit SLURM job"
    exit 1
fi

echo ""
echo "Monitoring job progress..."
echo "You can monitor the job status with: squeue -j $JOB_ID"
echo "View job output with: cat ./result/stringfinder_${JOB_ID}_*.out"
echo "View job errors with: cat ./result/stringfinder_${JOB_ID}_*.err"

# Function to check job status
check_job_status() {
    local job_id=$1
    squeue -j $job_id -h 2>/dev/null | wc -l
}

# Function to wait for job completion
wait_for_completion() {
    local job_id=$1
    local timeout=600  # 10 minutes timeout
    local elapsed=0
    local check_interval=10
    
    echo "Waiting for job completion (timeout: ${timeout}s)..."
    
    while [ $elapsed -lt $timeout ]; do
        local running_tasks=$(check_job_status $job_id)
        
        if [ $running_tasks -eq 0 ]; then
            echo "All tasks completed!"
            return 0
        fi
        
        echo "Tasks still running: $running_tasks (elapsed: ${elapsed}s)"
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    echo "Timeout reached. Some tasks may still be running."
    echo "Check manually with: squeue -j $job_id"
    return 1
}

# Wait for job completion
if wait_for_completion $JOB_ID; then
    echo ""
    echo "Job completed! Checking results..."
    
    # Check which evaluation files were created
    echo ""
    echo "Generated evaluation files:"
    ls -la ./result/evaluate_*.csv 2>/dev/null || echo "No evaluation files found"
    
    # Check time file
    if [ -f "./result/time.txt" ]; then
        echo ""
        echo "Wall clock times:"
        cat ./result/time.txt
    else
        echo "No time.txt file found"
    fi
    
    # Check for any errors in job output
    echo ""
    echo "Checking for errors in job output:"
    if ls ./result/stringfinder_${JOB_ID}_*.err 1> /dev/null 2>&1; then
        for err_file in ./result/stringfinder_${JOB_ID}_*.err; do
            if [ -s "$err_file" ]; then
                echo "Errors in $err_file:"
                cat "$err_file"
            fi
        done
    fi
    
    # Run R plotting script
    echo ""
    echo "Running R plotting script..."
    if [ -f "./script/plot_results.R" ]; then
        R_SCRIPT="./script/plot_results.R"
    else
        R_SCRIPT="./plot_results.R"
    fi
    
    if [ -f "$R_SCRIPT" ]; then
        chmod +x $R_SCRIPT
        Rscript $R_SCRIPT
        
        echo ""
        echo "Generated plot files:"
        ls -la ./result/plot_*.pdf 2>/dev/null || echo "No plot files found"
    else
        echo "R plotting script not found: $R_SCRIPT"
    fi
    
else
    echo ""
    echo "Job may still be running or failed. Please check manually:"
    echo "  squeue -j $JOB_ID"
    echo "  cat ./result/stringfinder_${JOB_ID}_*.out"
    echo "  cat ./result/stringfinder_${JOB_ID}_*.err"
fi

echo ""
echo "=== Final Summary ==="
echo "Job ID: $JOB_ID"
echo "Evaluation files: $(ls ./result/evaluate_*.csv 2>/dev/null | wc -l)/4"
echo "Plot files: $(ls ./result/plot_*.pdf 2>/dev/null | wc -l)"
echo "Completion time: $(date)"
echo ""
echo "All files are stored in the ./result/ directory"
echo "Scripts are stored in the ./script/ directory"