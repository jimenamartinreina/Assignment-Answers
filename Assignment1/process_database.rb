require 'csv'
require 'date'
require 'matrix'

# Class for Gene
class Gene
  attr_accessor :gene_id, :gene_name, :linked_genes

  def initialize(gene_id, gene_name)
    @gene_id = gene_id
    @gene_name = gene_name
    @linked_genes = []  # We initialize linked_genes as an empty array
  end

  def add_linked_gene(new_gene)
    @linked_genes << new_gene
  end

  def to_s
    "#{@gene_name} is linked to #{linked_genes.join(", ")}"
  end 
end


# Initialize an array for genes
genes = []

# Class for SeedStock
class SeedStock
  attr_accessor :seed_stock, :mutant_gene_id, :last_planted, :storage, :grams_remaining
  
  def initialize(seed_stock, mutant_gene_id, last_planted, storage, grams_remaining)
    @seed_stock = seed_stock
    @mutant_gene_id = mutant_gene_id
    @last_planted = Date.parse(last_planted)
    @storage = storage
    @grams_remaining = grams_remaining.to_i
  end
  
  def plant_seeds
    if @grams_remaining > 7
      @grams_remaining -= 7
    else
      puts "WARNING: we have run out of Seed Stock for #{@seed_stock}"
      @grams_remaining = 0
    end
    @last_planted = Date.today
  end
end
  
# Class for HybridCross
class HybridCross
  attr_accessor :parent1, :parent2, :f2_wild, :f2_p1, :f2_p2, :f2_p1p2, :chi_square_value

  def initialize(parent1, parent2, f2_wild, f2_p1, f2_p2, f2_p1p2, chi_square_value)
    @parent1 = parent1
    @parent2 = parent2
    @f2_wild = f2_wild.to_i
    @f2_p1 = f2_p1.to_i
    @f2_p2 = f2_p2.to_i
    @f2_p1p2 = f2_p1p2.to_i
    @chi_square_value = chi_square_value
  end

  def chi_square
    @chi_square_value
  end
end

# Load data from gene_information.tsv
CSV.foreach('gene_information.tsv', col_sep: "\t", headers: true) do |row|
  gene_id = row['Gene_ID']
  gene_name = row['Gene_name']
  new_gene = Gene.new(gene_id, gene_name)
  genes << new_gene
end

# Load data from seed_stock_data.tsv
seed_stocks = []
CSV.foreach('seed_stock_data.tsv', col_sep: "\t", headers: true) do |row|
  seed_stocks << SeedStock.new(row['Seed_Stock'], row['Mutant_Gene_ID'], row['Last_Planted'], row['Storage'], row['Grams_Remaining'])
end

# Load data from cross_data.tsv
hybrid_crosses = []
CSV.foreach('cross_data.tsv', col_sep: "\t", headers: true) do |row|
  f2_wild = row['F2_Wild'].to_f
  f2_p1 = row['F2_P1'].to_f
  f2_p2 = row['F2_P2'].to_f
  f2_p1p2 = row['F2_P1P2'].to_f
  #We use .to_f to convert the values to float numbers, because
  #if we don't do that, the expected values don't have decimals

  # We calculate the total observed for this row
  total_observed = f2_wild + f2_p1 + f2_p2 + f2_p1p2

  # We calculate the expected values for this row based on the 9:3:3:1 ratio
  expected = [total_observed * 9/16, total_observed * 3/16, total_observed * 3/16, total_observed * 1/16]

  chi_square_value = 0.0

  [f2_wild, f2_p1, f2_p2, f2_p1p2].each_with_index do |obs, i|
    chi_square_value += ((obs - expected[i])**2) / expected[i]
  end

  hybrid_crosses << HybridCross.new(row['Parent1'], row['Parent2'], f2_wild, f2_p1, f2_p2, f2_p1p2, chi_square_value)
end

# Simulate planting 7 grams of seeds and update the date
seed_stocks.each(&:plant_seeds)

# Perform Chi-square test and update gene links
hybrid_crosses.each do |cross|
  # Use cross.parent1 and cross.parent2 to find the corresponding gene IDs
  parent1_gene_id = seed_stocks.find { |stock| stock.seed_stock == cross.parent1 }&.mutant_gene_id
  parent2_gene_id = seed_stocks.find { |stock| stock.seed_stock == cross.parent2 }&.mutant_gene_id
  # Use cross.parent1 and cross.parent2 to find the corresponding gene IDs
  parent1_gene = genes.find { |gene| gene.gene_id == parent1_gene_id }
  parent2_gene = genes.find { |gene| gene.gene_id == parent2_gene_id }
  # Use the gene IDs to find the gene names in the gene_information.tsv
  parent1_gene_name = parent1_gene&.gene_name
  parent2_gene_name = parent2_gene&.gene_name

  if cross.chi_square_value > 7.815
    parent1_gene.add_linked_gene(parent2_gene_name)
    parent2_gene.add_linked_gene(parent1_gene_name)
    puts "Recording: #{parent1_gene_name} is genetically linked to #{parent2_gene_name} with chisquare score #{cross.chi_square}"
    puts "\n"
  end
end

# Save updated data to new_stock_file.tsv
CSV.open('new_stock_file.tsv', 'w', col_sep: "\t") do |csv|
  csv << ['Seed_Stock', 'Mutant_Gene_ID', 'Last_Planted', 'Storage', 'Grams_Remaining']

  seed_stocks.each do |seed_stock|
    csv << [seed_stock.seed_stock, seed_stock.mutant_gene_id, seed_stock.last_planted, seed_stock.storage, seed_stock.grams_remaining]
  end
end

# Print final report
puts "\nFinal Report:"
puts "\n"
genes.each do |gene|
  if gene.is_a?(Gene) && !gene.linked_genes.empty?
    puts gene
  end
end
