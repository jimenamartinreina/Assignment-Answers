# Class for annotating networks with KEGG and GO pathway information.
class Annotate
  # Annotates networks with KEGG pathway information.
  # @param networks [Array] List of networks to annotate.
  def self.kegg_pathways(networks)
    networks.each do |network|
      network_kegg_ids = []
      network_kegg_names = []
      network.components.each do |gene|
        ids, names = Annotate.find_kegg_data(gene)
        ids.each do |id|
          network.kegg_ids << id
        end
        names.each do |name|
          network.kegg_names << name
        end
      end
    end
  end

  # Finds KEGG pathway data for a given gene.
  # @param gene [String] Gene for which KEGG data is searched.
  # @return [Array] Two arrays containing KEGG IDs and names.
  def self.find_kegg_data(gene)
    kegg_url = "http://togows.org/entry/kegg-genes/ath:#{gene}/pathways.json"
    uri = URI(kegg_url)
    response = Net::HTTP.get(uri)
    data = JSON.parse(response)
    if data[0]
      return data[0].keys, data[0].values
    else
      return [], []
    end
  end
  
  # Annotates networks with GO pathway information.
  # @param networks [Array] List of networks to annotate.
  def self.go_pathways(networks)
    networks.each do |network|
      network_go_ids = []
      network.components.each do |gene|
        ids, names = Annotate.find_go_data(gene)
        ids.each do |id|
          network.go_ids << id
        end
        names.each do |name|
          network.go_names << name
        end
      end
    end
  end

  # Finds GO pathway data for a given gene.
  # @param gene [String] Gene for which GO data is sought.
  # @return [Array] Two arrays containing GO IDs and names.
  def self.find_go_data(gene)
    go_url = "http://togows.dbcls.jp/entry/uniprot/#{gene}/dr.json"
    response = RestClient::Request.execute(method: :get, url: go_url)
    data = JSON.parse(response.body)
    ids = []
    names =[]
    go_data = data[0]["GO"]
    if go_data
      go_data.each do |go_process|
        if go_process[1] =~ /^P/
          ids << go_process[0]
          names << go_process[1].sub(/^P:/, '') 
        end
      end   
    end
    return ids.uniq, names.uniq
  end
end
