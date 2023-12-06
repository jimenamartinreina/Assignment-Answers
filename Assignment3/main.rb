require_relative 'methods'
require_relative 'gene'
require 'bio'
require 'rest-client'

# Initial file with genes' IDs.
gene_ids_file = 'ArabidopsisSubNetwork_GeneList.txt'
# In this case the target we are searching in sequences is CTTCTT
target = Bio::Sequence::NA.new('cttctt')
# The script will have three output files, two .gff and one .txt.
gff_4a = 'target_matches_4a.gff'
no_matches_report = 'no_matches_report.txt'
gff_5 = 'target_matches_5.gff'

# Execute the functions of the secondary script "methods.rb"
genes = Method.fetch_and_annotate_sequences(gene_ids_file, target)
Method.write_gff_file_4a(genes, gff_4a)
Method.write_no_matches_report(genes, no_matches_report)
Method.write_gff_file_5(genes, gff_5)