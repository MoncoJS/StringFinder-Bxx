#!/bin/bash

#SBATCH --job-name=string_finder
#SBATCH --output=string_finder_%j.out
#SBATCH --error=string_finder_%j.err
#SBATCH --time=00:05:00
#SBATCH --ntasks=4

# Create result directory if it doesn't exist
mkdir -p result

# Function to run a single task
run_task() {
    local run_id=$1
    # Run Java program with specific run ID
    java -Drun.id=$run_id -cp bin StringFinder
}

# Run 4 tasks in parallel
for i in {01..04}; do
    run_task $i &
done

# Wait for all background processes to complete
wait 