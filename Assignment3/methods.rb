# Class containing methods for gene manipulation and annotation.
class Method
  # Retrieves sequences and annotates gene features.
  # @param gene_ids_file [String] Path to the file containing gene IDs.
  # @param target [String] Target sequence for annotation.
  # @return [Array<Gene>] An array of annotated Gene objects.
  def self.fetch_and_annotate_sequences(gene_ids_file, target)
    @genes = []
    File.foreach(gene_ids_file) do |gene_id|
      gene_id.chomp!
      address = "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{gene_id}"
      response = RestClient.get(address)
      embl = Bio::EMBL.new(response)
      gene = Gene.new(gene_id, embl)
      Method.annotate_features(gene, target)
      @genes << gene
    end
    return @genes
  end
  # Annotates exon features of a gene (position in the gene).
  # @param gene [Gene] Gene object to annotate.
  # @param target [String] Target sequence for annotation.
  # @return [void]
  def self.annotate_features(gene, target)
    gene.embl.features.each do |feat|
      if feat.qualifiers[0].value.downcase.include?("exon_id=#{gene.id.downcase}")
        match = /(\d+)\.\.(\d+)/.match(feat.position)
        unless match.nil?
          start_position = match[1].to_i
          end_position = match[2].to_i
          Method.find_matches(gene, start_position, end_position, target, '+')
          Method.find_matches(gene, start_position, end_position, target.complement, '-')
        else
          puts "Error: Could not extract the position of feature #{feat}." 
        end
      end
    end
  end
  # Searches for matches of CTTCTT in the exons sequences and creates new targets features.
  # The position in this target feature is the position of CTTCTT in the gene.
  # @param gene [Gene] Gene object to search for matches.
  # @param start_position [Integer] Starting position of the search.
  # @param end_position [Integer] Ending position of the search.
  # @param target [String] Target sequence for the search.
  # @param strand [String] String indicating the strand (+ or -).
  # @return [void]
  def self.find_matches(gene, start_position, end_position, target, strand)
    gene.embl.seq.subseq(start_position,end_position).scan(target) do |scan|      
      unless gene.embl.features.any? { |feat| feat.feature == "Target" and feat.position == "#{Regexp.last_match.begin(0) + start_position}..#{Regexp.last_match.end(0) + start_position - 1}" }
        if gene.embl.features.any? { |feat| feat.feature == "Target" and feat.position == "#{Regexp.last_match.begin(0) + start_position - 6}..#{Regexp.last_match.end(0) + start_position - 7}" }
          Method.create_new_feature(gene,strand,Regexp.last_match.begin(0) - 3,start_position)          
        end
        if gene.embl.features.any? { |feat| feat.feature == "Target" and feat.position == "#{Regexp.last_match.begin(0) + start_position + 6}..#{Regexp.last_match.end(0) + start_position + 5}" }
          Method.create_new_feature(gene,strand,Regexp.last_match.begin(0) + 3,start_position)          
        end
        Method.create_new_feature(gene,strand,Regexp.last_match.begin(0),start_position)
      end
    end
  end
  # Creates a new feature and adds it to the gene.
  # @param gene [Gene] Gene object to which the new feature will be added.
  # @param strand [String] String indicating the strand (+ or -).
  # @param first [Integer] Starting position of the new feature.
  # @param start_position [Integer] Starting position of the gene.
  # @return [void]
  def self.create_new_feature(gene, strand, first, start_position)
    target_feature = Bio::Feature.new('Target', "#{first + start_position}..#{first + start_position + 5}")
    target_feature.append(Bio::Feature::Qualifier.new('strand',strand))
    gene.embl.features << target_feature
  end
  # Writes a GFF file for specific features found in the sequences of the genes.
  # @param genes [Array<Gene>] Array of genes to write to the GFF file.
  # @param outfile [String] Output file path.
  # @return [void]
  def self.write_gff_file_4a(genes, outfile)
    i = 1
    File.open(outfile, 'w') do |report|
      report.puts "##gff-version 3"
      genes.each do |gene|
        gene.embl.features.each do |feat|
          gff_line = []
          if feat.feature == 'Target'
            match = /(\d+)\.\.(\d+)/.match(feat.position)
            gff_line << "#{gene.id}"
            gff_line << "."
            gff_line << "Target_sequence(CTTCTT)"            
            gff_line << "#{match[1]}"
            gff_line << "#{match[2]}"
            gff_line << "."
            gff_line << "#{feat.qualifiers[0].value}"
            gff_line << "."
            gff_line << "ID=target#{format('%05d', i)}"
            i += 1   
            report.puts gff_line.join("\t")
          end
        end
      end
    end
  end
  # Writes a report for genes with no CTTCTT in their exons.
  # @param genes [Array<Gene>] Array of genes to check.
  # @param outfile [String] Output file path.
  # @return [void]
  def self.write_no_matches_report(genes, outfile)
    File.open(outfile, 'w') do |report|
      report.puts "No matches found for the following genes:"
      genes.each do |gene|
        has_target = gene.embl.features.any? { |feat| feat.feature == "Target" }
        report.puts gene.id unless has_target
      end
    end
  end
  # Writes a GFF file using additional gene information, the number of chromosome and the #position of CTTCTT in that chromosome of the genome.
  # @param genes [Array<Gene>] Array of genes to write to the GFF file.
  # @param outfile [String] Output file path.
  # @return [void]
  def self.write_gff_file_5(genes, outfile)
    i = 1
    File.open(outfile, 'w') do |report|
      report.puts "##gff-version 3"
      genes.each do |gene|
        gene.embl.features.each do |feat|
          gff_line = []
          if feat.feature == 'Target'
            sv = gene.embl.sv.split(":")
            match = /(\d+)\.\.(\d+)/.match(feat.position)            
            gff_line << "#{sv[2]}"
            gff_line << "custom"
            gff_line << "Target_sequence(CTTCTT)"
            gff_line << "#{match[1].to_i + sv[3].to_i - 1}"
            gff_line << "#{match[2].to_i + sv[3].to_i - 1}"
            gff_line << "."
            gff_line << "#{feat.qualifiers[0].value}"
            gff_line << "."
            gff_line << "ID=target#{format('%05d', i)}"            
            i += 1  
            report.puts gff_line.join("\t")
          end
        end
      end
    end
  end
end