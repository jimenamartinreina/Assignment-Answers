# Required libraries for the script
require 'rest-client'
require 'json'
require 'uri'
require './Interactions.rb'
require './Network.rb'
require './Annotations.rb'
require 'net/http'

# Specify the input gene list and the report files.
gene_list_file = 'ArabidopsisSubNetwork_GeneList.txt'
output_file = 'interactions.txt'
report_file = 'report.txt'

#Quality threshold to consider interactions between proteins.
quality = 0.4

# Call the method to fetch and save interaction information
int_array = Interaction.fetch_and_save(gene_list_file, output_file, quality)
# Identify networks from the interaction data
networks = Network.identify_networks(int_array)
# Annotate networks with KEGG and GO pathway information
Annotate.kegg_pathways(networks)
Annotate.go_pathways(networks)
# Print a report of the identified networks
Network.print_report(networks, report_file)