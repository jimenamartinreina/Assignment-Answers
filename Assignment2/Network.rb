# Class representing a protein network.
class Network
  # Accessors for the network attributes.
  attr_accessor :components, :kegg_ids, :kegg_names, :go_ids, :go_names
  # Initializes a new instance of the network with the given components.
  # @param components [Array] List of network components.
  def initialize(components)
    @components = components
    @kegg_ids = []
    @kegg_names = []
    @go_ids = []
    @go_names = []
  end
  
  # Identifies and returns networks from given interactions.
  # @param interactions [Array] List of interactions.
  # @return [Array] List of identified networks.
  def self.identify_networks(interactions)
    @interactions = interactions
    networks = []
    @interactions.each do |interaction|
      if interaction[3] == "unchecked"
        networks << Network.new_network(interaction)
      end
    end
    return networks
  end
  
  # Creates a new network from a given interaction.
  # @param interaction [Array] Interaction from which the network is created.
  # @return [Network] Newly created network.
  def self.new_network(interaction)
    networks = []
    new_gene_list = interaction[0..1]
    gene_list = []
    loop do
      gene_list += new_gene_list      
      updated_gene_list = []
      new_gene_list.each do |gene|
        new_genes = Network.find_ints(gene)
        updated_gene_list += new_genes
      end
      break if updated_gene_list.empty?  # Break the loop if no new genes are added
      new_gene_list = updated_gene_list
    end
    return Network.new(gene_list.uniq(&:downcase))
  end
  
  # Finds interactions for a given gene.
  # @param gene [String] Gene for which interactions are searched.
  # @return [Array] List of genes that interact with the given gene.
  def self.find_ints(gene)
    int_genes = []
    @interactions.each_with_index do |interaction, index|
      if interaction[3] == "unchecked"
        if interaction[0] == gene
          int_genes << interaction[1]
          @interactions[index][3] = "checked"
        elsif interaction[1] == gene
          int_genes << interaction[0]
          @interactions[index][3] = "checked"
        end
      end
    end
    return int_genes
  end
  
  # Prints a report of the networks to a given file.
  # @param networks [Array] List of networks to print in the report.
  # @param outfile [String] Output file name.
  def self.print_report(networks, outfile)
    report = File.open(outfile, 'w')
    report.puts "******** Bioinformatics Programming Challenges"
    report.puts "******** Assignment 2 - Intensive integration using web APIs"
    report.puts "******** David García Valcarce"
    report.puts "******** Jimena Martín Reina"
    report.puts "\nA total of #{networks.length} networks were found.\n\n"
    report.puts "------------------------------------------------"
    networks.each_with_index do |network, index|
      report.puts "**NETWORK #{index + 1}"
      report.puts "---"
      report.puts "*GENES:"
      report.puts network.components
      report.puts "---"
      report.puts "*KEGG PATHWAYS:"
      network.kegg_ids.each_with_index do |kegg_id, index2|
        report.puts "#{kegg_id}: #{network.kegg_names[index2]}"
      end
      report.puts "---"
      report.puts "*GO PROCESSES:"
      network.go_ids.each_with_index do |go_id, index3|
        report.puts "#{go_id}: #{network.go_names[index3]}"
      end
      report.puts "------------------------------------------------"
    end
  end
end