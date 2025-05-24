#!/usr/bin/env Rscript

# Load required libraries
if (!require("ggplot2", quietly = TRUE)) {
    install.packages("ggplot2", repos = "http://cran.r-project.org")
    library(ggplot2)
}

# Ensure required directories exist
if (!dir.exists("./result")) {
    dir.create("./result", recursive = TRUE)
    cat("Created result directory\n")
}

if (!dir.exists("./script")) {
    dir.create("./script", recursive = TRUE)
    cat("Created script directory\n")
}

# Function to create plot for a specific run
create_plot <- function(run_id) {
    # Read CSV file
    filename <- paste0("./result/evaluate_", sprintf("%02d", run_id), ".csv")
    
    tryCatch({
        if (!file.exists(filename)) {
            cat("Warning: File", filename, "does not exist. Skipping...\n")
            return(FALSE)
        }
        
        # Read data
        data <- read.csv(filename, stringsAsFactors = FALSE)
        if (nrow(data) == 0) {
            cat("Warning: Empty data in", filename, ". Skipping...\n")
            return(FALSE)
        }
        
        cat("Processing", filename, "with", nrow(data), "data points\n")
        
        # Create PDF plot
        pdf_filename <- paste0("./result/plot_", sprintf("%02d", run_id), ".pdf")
        pdf(pdf_filename, width = 10, height = 6)
        
        # Create the plot using base R
        plot(data$pass_no, data$evaluate,
             type = "l",
             col = "blue",
             lwd = 2,
             main = paste("StringFinder Convergence - Run", sprintf("%02d", run_id)),
             xlab = "Pass Number (Evaluation Count)",
             ylab = "Evaluate Score (Incorrect Characters)",
             sub = paste("Total evaluations:", max(data$pass_no)),
             cex.main = 1.2,
             cex.lab = 1.1)
        
        # Add points for better visibility
        points(data$pass_no, data$evaluate, 
               col = "red", 
               pch = 16, 
               cex = 0.5)
        
        # Add grid for better readability
        grid(col = "lightgray", lty = "dotted")
        
        # Add a horizontal line at y=0 to show the target
        abline(h = 0, col = "green", lwd = 2, lty = "dashed")
        
        # Add legend
        legend("topright", 
               legend = c("Convergence Line", "Data Points", "Target (Score = 0)"),
               col = c("blue", "red", "green"),
               lty = c(1, NA, 2),
               pch = c(NA, 16, NA),
               lwd = c(2, NA, 2),
               cex = 0.8)
        
        # Add text box with final statistics
        final_score <- tail(data$evaluate, 1)
        text(x = max(data$pass_no) * 0.7, 
             y = max(data$evaluate) * 0.8,
             labels = paste("Final Score:", final_score,
                           "\nSuccess:", ifelse(final_score == 0, "YES", "NO")),
             bg = "white",
             cex = 0.9)
        
        dev.off()
        cat("Created plot:", pdf_filename, "\n")
        return(TRUE)
        
    }, error = function(e) {
        cat("Error processing run", run_id, ":", e$message, "\n")
        return(FALSE)
    })
}

# Function to create combined plot
create_combined_plot <- function(successful_runs) {
    if (length(successful_runs) == 0) {
        cat("No successful runs to combine\n")
        return(FALSE)
    }
    
    pdf("./result/plot_combined.pdf", width = 12, height = 8)
    
    # Set up colors for different runs
    colors <- c("blue", "red", "green", "purple")
    
    # Initialize plot with first run
    first_run <- successful_runs[1]
    filename <- paste0("./result/evaluate_", sprintf("%02d", first_run), ".csv")
    data <- read.csv(filename, stringsAsFactors = FALSE)
    
    plot(data$pass_no, data$evaluate,
         type = "l",
         col = colors[1],
         lwd = 2,
         main = "StringFinder Convergence - All Runs Comparison",
         xlab = "Pass Number (Evaluation Count)",
         ylab = "Evaluate Score (Incorrect Characters)",
         xlim = c(0, max(sapply(successful_runs, function(r) {
             d <- read.csv(paste0("./result/evaluate_", sprintf("%02d", r), ".csv"))
             max(d$pass_no)
         }))),
         ylim = c(0, max(sapply(successful_runs, function(r) {
             d <- read.csv(paste0("./result/evaluate_", sprintf("%02d", r), ".csv"))
             max(d$evaluate)
         }))),
         cex.main = 1.2,
         cex.lab = 1.1)
    
    # Add other runs
    if (length(successful_runs) > 1) {
        for (i in 2:length(successful_runs)) {
            run_id <- successful_runs[i]
            filename <- paste0("./result/evaluate_", sprintf("%02d", run_id), ".csv")
            data <- read.csv(filename, stringsAsFactors = FALSE)
            lines(data$pass_no, data$evaluate, 
                  col = colors[i], 
                  lwd = 2)
        }
    }
    
    # Add grid and target line
    grid(col = "lightgray", lty = "dotted")
    abline(h = 0, col = "darkgreen", lwd = 2, lty = "dashed")
    
    # Add legend
    legend_labels <- paste("Run", sprintf("%02d", successful_runs))
    legend_labels <- c(legend_labels, "Target (Score = 0)")
    legend_colors <- c(colors[1:length(successful_runs)], "darkgreen")
    legend_lty <- c(rep(1, length(successful_runs)), 2)
    legend_lwd <- c(rep(2, length(successful_runs)), 2)
    
    legend("topright", 
           legend = legend_labels,
           col = legend_colors,
           lty = legend_lty,
           lwd = legend_lwd,
           cex = 0.8)
    
    dev.off()
    cat("Created combined plot: ./result/plot_combined.pdf\n")
    return(TRUE)
}

# Function to wait for files with timeout
wait_for_files <- function(timeout = 120) {
    start_time <- Sys.time()
    cat("Waiting for evaluation files to be generated...\n")
    
    while(TRUE) {
        missing_files <- c()
        existing_files <- c()
        
        for (i in 1:4) {
            file <- paste0("./result/evaluate_", sprintf("%02d", i), ".csv")
            if (!file.exists(file)) {
                missing_files <- c(missing_files, file)
            } else {
                existing_files <- c(existing_files, file)
            }
        }
        
        if (length(existing_files) > 0) {
            cat("Found files:", paste(basename(existing_files), collapse=", "), "\n")
        }
        
        if (length(missing_files) == 0) {
            cat("All evaluation files found!\n")
            return(TRUE)
        }
        
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units="secs"))
        if (elapsed > timeout) {
            cat("Timeout after", timeout, "seconds. Missing files:", 
                paste(basename(missing_files), collapse=", "), "\n")
            cat("Will proceed with available files.\n")
            return(FALSE)
        }
        
        if (elapsed %% 15 == 0) {  # Report every 15 seconds
            cat("Still waiting... Elapsed:", round(elapsed), "seconds\n")
        }
        
        Sys.sleep(5)  # Wait 5 seconds before checking again
    }
}

# Main execution
cat("=== StringFinder Results Plotting Script ===\n")
cat("Starting at:", format(Sys.time()), "\n")

# Wait for files (but don't require all of them)
wait_for_files(timeout = 60)

cat("Starting plot generation...\n")

# Create individual plots
successful_plots <- c()
for (i in 1:4) {
    if (create_plot(i)) {
        successful_plots <- c(successful_plots, i)
    }
}

# Create combined plot if we have at least one successful plot
if (length(successful_plots) > 0) {
    create_combined_plot(successful_plots)
    cat("Successfully created", length(successful_plots), "individual plots and 1 combined plot\n")
} else {
    cat("Error: No plots were created due to missing or invalid data\n")
    quit(status=1)
}

# Display summary
cat("\n=== Summary ===\n")
cat("Successful plots:", length(successful_plots), "out of 4\n")
cat("Plot files created:\n")
for (run_id in successful_plots) {
    pdf_file <- paste0("./result/plot_", sprintf("%02d", run_id), ".pdf")
    if (file.exists(pdf_file)) {
        cat("  -", pdf_file, "\n")
    }
}
if (file.exists("./result/plot_combined.pdf")) {
    cat("  - ./result/plot_combined.pdf\n")
}

cat("Plot generation completed at:", format(Sys.time()), "\n")