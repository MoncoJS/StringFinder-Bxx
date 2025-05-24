import java.io.*;
import java.util.*;

public class StringFinder {
    
    public Secret getGoal() {
        return goal;
    }

    public void setGoal(Secret goal) {
        this.goal = goal;
    }

    private Secret goal;
    private int passCount = 0;
    private List<String> evaluationLog = new ArrayList<>();
    
    public StringFinder(Secret goal){
        this.goal = goal;
    }
    
    public String find() {
        // Improved Genetic Algorithm parameters
        int populationSize = 150; // Increased population
        int maxGenerations = 500; // Reduced max generations
        double mutationRate = 0.15; // Increased mutation rate
        int tournamentSize = 7; // Increased tournament size
        int targetLength = goal.evaluate("") + 1; // Better initial length guess
        
        // Initialize population with improved initial guess
        List<Individual> population = initializePopulation(populationSize, targetLength);
        
        String bestString = "";
        int bestScore = Integer.MAX_VALUE;
        int stagnationCount = 0;
        
        for (int generation = 0; generation < maxGenerations; generation++) {
            // Evaluate all individuals
            for (Individual individual : population) {
                int score = evaluateWithLog(individual.genes);
                individual.fitness = score;
                
                // Track best solution
                if (score < bestScore) {
                    bestScore = score;
                    bestString = individual.genes;
                }
                
                // If we found the perfect match, return it
                if (score == 0) {
                    return bestString;
                }
            }
            
            // Sort population by fitness (lower is better)
            Collections.sort(population, (a, b) -> Integer.compare(a.fitness, b.fitness));
            
            // Adaptive mutation rate based on population diversity
            double diversity = calculateDiversity(population);
            mutationRate = 0.15 + (1.0 - diversity) * 0.2; // Adjust mutation rate
            
            // Adaptive population size based on progress
            if (generation % 20 == 0 && stagnationCount > 5) {
                populationSize = Math.min(300, (int)(populationSize * 1.2));
                stagnationCount = 0;
            }
            
            // Create new generation with improved selection pressure
            List<Individual> newPopulation = new ArrayList<>();
            
            // Increased elitism percentage
            int eliteCount = populationSize / 8;
            for (int i = 0; i < eliteCount; i++) {
                newPopulation.add(new Individual(population.get(i).genes));
            }
            
            // Fill rest with improved crossover and mutation
            while (newPopulation.size() < populationSize) {
                Individual parent1 = tournamentSelection(population, tournamentSize);
                Individual parent2 = tournamentSelection(population, tournamentSize);
                
                Individual child = crossover(parent1, parent2);
                mutate(child, mutationRate);
                
                newPopulation.add(child);
            }
            
            population = newPopulation;
        }
        
        return bestString;
    }
    
    // Initialize population with random strings
    private List<Individual> initializePopulation(int size, int length) {
        List<Individual> population = new ArrayList<>();
        String charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ";
        Random random = new Random();
        
        for (int i = 0; i < size; i++) {
            StringBuilder sb = new StringBuilder();
            int actualLength = Math.max(1, length + random.nextInt(11) - 5); // Length variation
            
            for (int j = 0; j < actualLength; j++) {
                sb.append(charset.charAt(random.nextInt(charset.length())));
            }
            
            population.add(new Individual(sb.toString()));
        }
        
        return population;
    }
    
    // Tournament selection
    private Individual tournamentSelection(List<Individual> population, int tournamentSize) {
        Random random = new Random();
        Individual best = null;
        
        for (int i = 0; i < tournamentSize; i++) {
            Individual candidate = population.get(random.nextInt(population.size()));
            if (best == null || candidate.fitness < best.fitness) {
                best = candidate;
            }
        }
        
        return best;
    }
    
    // Single-point crossover
    private Individual crossover(Individual parent1, Individual parent2) {
        Random random = new Random();
        String genes1 = parent1.genes;
        String genes2 = parent2.genes;
        
        int minLength = Math.min(genes1.length(), genes2.length());
        if (minLength <= 1) {
            return new Individual(random.nextBoolean() ? genes1 : genes2);
        }
        
        int crossoverPoint = random.nextInt(minLength);
        
        String childGenes = genes1.substring(0, crossoverPoint) + 
                           genes2.substring(crossoverPoint);
        
        return new Individual(childGenes);
    }
    
    // Improve mutation method
    private void mutate(Individual individual, double mutationRate) {
        Random random = new Random();
        String charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ";
        StringBuilder sb = new StringBuilder(individual.genes);
        
        // Intelligent mutation - higher chance to mutate characters with high error
        for (int i = 0; i < sb.length(); i++) {
            if (random.nextDouble() < mutationRate) {
                // Prefer space and alphanumeric characters
                double charType = random.nextDouble();
                char newChar;
                if (charType < 0.4) // 40% chance for letters
                    newChar = (char)('A' + random.nextInt(26));
                else if (charType < 0.7) // 30% chance for lowercase
                    newChar = (char)('a' + random.nextInt(26));
                else if (charType < 0.9) // 20% chance for numbers
                    newChar = (char)('0' + random.nextInt(10));
                else // 10% chance for space
                    newChar = ' ';
                
                sb.setCharAt(i, newChar);
            }
        }
        
        // Smart length mutation
        if (random.nextDouble() < mutationRate / 2) {
            if (individual.fitness > 5) { // More likely to change length if fitness is poor
                if (random.nextBoolean() && sb.length() < 30)
                    sb.append(charset.charAt(random.nextInt(charset.length())));
                else if (sb.length() > 1)
                    sb.deleteCharAt(random.nextInt(sb.length()));
            }
        }
        
        individual.genes = sb.toString();
    }
    
    // Add new helper method to calculate population diversity
    private double calculateDiversity(List<Individual> population) {
        Set<String> uniqueGenes = new HashSet<>();
        for (Individual ind : population) {
            uniqueGenes.add(ind.genes);
        }
        return (double)uniqueGenes.size() / population.size();
    }
    
    // Evaluate with logging
    private int evaluateWithLog(String input) {
        passCount++;
        int score = goal.evaluate(input);
        evaluationLog.add(passCount + "," + score);
        return score;
    }
    
    // Save evaluation log to CSV file
    private void saveEvaluationLog(String filename) {
        try (PrintWriter writer = new PrintWriter(new FileWriter(filename))) {
            writer.println("pass_no,evaluate");
            for (String entry : evaluationLog) {
                writer.println(entry);
            }
        } catch (IOException e) {
            System.err.println("Error writing to file: " + e.getMessage());
        }
    }
    
    public static void main(String[] args) {
        
        // DO NOT MODIFY THIS LINE
        StringFinder finder = new StringFinder(new Secret("Parallel Programming"));
        
        ///-----------------------------
        // MODIFY/ADD YOUR CODE HERE
        //
        
        long startTime = System.nanoTime();
        
        String str = finder.find();
        while(finder.goal.evaluate(str) != 0){
            str = finder.find();
        }
        
        long endTime = System.nanoTime();
        long wallClockTime = endTime - startTime;
        
        // Save evaluation log
        String runId = System.getProperty("run.id", "01");
        finder.saveEvaluationLog("./result/evaluate_" + runId + ".csv");
        
        // Save wall clock time
        try (PrintWriter timeWriter = new PrintWriter(new FileWriter("./result/time.txt", true))) {
            timeWriter.println("Run " + runId + ": " + wallClockTime + " nanoseconds");
        } catch (IOException e) {
            System.err.println("Error writing time file: " + e.getMessage());
        }
        
        //
        // End of your modification
        //-----------------------------

        // print out the message find so far
        System.out.println("The secret message is: "+str);
        System.out.println("Total evaluations: " + finder.passCount);
        System.out.println("Wall clock time: " + wallClockTime + " nanoseconds");
        
    }

}

// Individual class for Genetic Algorithm
class Individual {
    String genes;
    int fitness;
    
    public Individual(String genes) {
        this.genes = genes;
        this.fitness = Integer.MAX_VALUE;
    }
}

// DO NOT MODIFY Secret CLASS
class Secret{
    private String data;
    
    public Secret(String data){
        this.data = data;
    }
    
    /**
     *  compare an input string to the goal.
     * @param input
     * @return the number of incorrect characters. It returns 0 when the input string exactly matches the data string.
     */
    public int evaluate(String input){
        int nchargoal = data.length();
        int nchar = input.length();
        int incorrect = 0;
        
        for (int i = 0; i < input.length(); i++) {
            if(i < nchargoal){
                if (input.charAt(i) != data.charAt(i)) 
                    incorrect++;
            }else
                incorrect++;
        }
        
        if(nchargoal > nchar)
            incorrect += nchargoal-nchar;
        
        return incorrect;
    }
}