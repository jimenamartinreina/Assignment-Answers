Work by David Garcia Valcarce and Jimena Martín Reina

Note: you will see the arabidopsis_aa.fa is empty, so in the dbs folder you won't see the three files for Arabidopsis. This is because we had a problem when updating files to GitHub, but if you run the code with the correct two input files, these database is correctly created. You can run only the first part of the code that creates the databases so it is not that long.
------------------------------------------
Usage: ruby main.rb 
The scripts expects a nt fasta file called TAIR10_cds_20101214_updated.fa and an aa fasta file called pep.fa
------------------------------------------
The filter used for the blastp was an e-value lower than 10e-6. This value was used in multiple papers for the purpose of finding reciprocal best blasts, for example: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7585182/

