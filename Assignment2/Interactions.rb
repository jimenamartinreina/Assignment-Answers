# Class representing interactions with genes using the IntAct service.
class Interaction
  # Fetches protein interactions for a list of genes and saves the results.
  # @param gene_list_file [String] Path to the file containing a list of genes.
  # @param output_file [String] Path to the output file for storing interactions.
  # @param quality [Float] Minimum quality score for considering an interaction.
  # @return [Array] Array of arrays containing interaction information.
  def self.fetch_and_save(gene_list_file, output_file, quality)
    gene_list = File.read(gene_list_file).split("\n").map(&:strip)
    int_array = []
    output_file = File.open(output_file, 'w')
    gene_list.each do |gene_of_interest|
      url = "http://www.ebi.ac.uk/Tools/webservices/psicquic/intact/webservices/current/search/interactor/#{gene_of_interest}?query=species:arabidopsis&format=tab25"
      response = RestClient.get(url)
      
      response.split("\n").each do |line|
        if !line.nil? && !line.empty?
          score_info = line.scan(/intact-miscore:(0.\d+)/)
          response_genes = line.scan(/(At\dg\d{5})/)
          if score_info[0][0] && response_genes
            score = score_info[0][0].to_f
                    
            if score && score >= quality && response_genes[0] && response_genes[1]
              interaction_info = []
              
              interaction_info[0] = response_genes[0][0]
              interaction_info[1] = response_genes[1][0]
              interaction_info[2] = score
              interaction_info[3] = "unchecked"

              unless int_array.include?(interaction_info)
                int_array << interaction_info
              end
            end
          end
        end
      end
    end
    output_file.puts "Interactions found between proteins in #{int_array.length} pairs"
    output_file.puts "id1\tid2\tscore" 
    int_array.each do |interaction_info|
      output_file.puts interaction_info[0..2].join(",")
    end
    output_file.close
    return int_array
  end
end