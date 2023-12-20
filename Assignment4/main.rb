require 'bio'
require 'stringio'
# Translate sequences from an Arabidopsis NT FASTA file to amino acids and save them in a new FASTA file.
#
# @example
#   # Sample usage:
#   # ruby script_name.rb
#
File.open('arabidopsis_aa.fa', 'w') do |new_fasta|
  arabidopsis_fasta_nt = Bio::FlatFile.open(Bio::FastaFormat, 'TAIR10_cds_20101214_updated.fa')
    # Iterate through each sequence in the Arabidopsis NT FASTA file.
  arabidopsis_fasta_nt.each do |fasta|
    new_fasta.puts ">#{fasta.definition}"
    new_fasta.puts Bio::Sequence.auto(fasta.seq.to_s).translate
  end
end
# Create directories for the BLAST databases.
system('mkdir dbs')
# Create BLAST databases for Arabidopsis and pombe protein sequences.
#
# @note The directories are created to store the BLAST databases.
system('makeblastdb -in arabidopsis_aa.fa -dbtype prot -out dbs/arabidopsis')
system('makeblastdb -in pep.fa -dbtype prot -out dbs/pombe')
# Open the pombe protein FASTA file for processing.
pombe_fasta = Bio::FlatFile.open(Bio::FastaFormat, 'pep.fa')
# Set up local BLAST factories for Arabidopsis and pombe databases.
arabidopsis_factory = Bio::Blast.local('blastp', 'dbs/arabidopsis', '-e 10e-6')
pombe_factory = Bio::Blast.local('blastp', 'dbs/pombe', '-e 10e-6')
# Generate a homology report using reciprocal-best-BLAST between S. pombe and A. thaliana genes.
File.open('homology_report.txt', 'w') do |report|
  report.puts "***Homology report"
  report.puts "These pairs of genes were obtained by reciprocal-best-BLAST"
  report.puts "S. pombe\tA. thaliana"
  # Iterate over each gene in the pombe FASTA file.
  pombe_fasta.each do |pombe_gene|
    hit_pair = []
    hit_pair << pombe_gene.definition.split('|')[0].to_s
        # Perform BLAST search against the Arabidopsis database using the pombe gene sequence.
    blast = arabidopsis_factory.query(pombe_gene.seq.to_s)
    blast.each do |hit|
      hit_pair << hit.definition.split('|')[0].to_s
      break
    end
    # Iterate over each gene in the translated Arabidopsis FASTA file.
    arabidopsis_fasta = Bio::FlatFile.open(Bio::FastaFormat, 'arabidopsis_aa.fa')
    arabidopsis_fasta.each do |arabidopsis_gene|
      if arabidopsis_gene.definition.split('|')[0].to_s == hit_pair[1]
              # Perform BLAST search against the pombe database using the Arabidopsis gene sequence.
        blast = pombe_factory.query(arabidopsis_gene.seq.to_s)
        blast.each do |hit|
          if hit.definition.split('|')[0].to_s == hit_pair[0]
            report.puts hit_pair.join("\t")
          end
          break
        end
        break
      end
    end
  end
end
