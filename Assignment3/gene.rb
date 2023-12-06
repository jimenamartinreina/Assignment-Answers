# The Gene class represents a gene with its associated EMBL data.
class Gene
  # @!attribute [rw] id
  #   @return [String] The identifier of the gene.
  attr_accessor :id

  # @!attribute [rw] embl
  #   @return [Bio::EMBL] The EMBL data associated with the gene.
  attr_accessor :embl

  # Initializes a new instance of the Gene class.
  # @param gene_id [String] The identifier of the gene.
  # @param embl [Bio::EMBL] The EMBL data associated with the gene.
  def initialize(gene_id, embl)
    @id = gene_id
    @embl = embl
  end
end
