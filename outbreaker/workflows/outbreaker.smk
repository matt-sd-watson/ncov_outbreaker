
rule all:
    input:
        os.path.join(config["outdir"], "outbreak.fa"),
        os.path.join(config["outdir"], "outbreak_renamed.fa") if config["rename"] else [],
        os.path.join(config["outdir"], "outbreak_aln.fasta"),
        os.path.join(config["outdir"], "tree.nwk"),
        os.path.join(config["outdir"], "snps_only.fasta") if config["snps_only"] else [],
        os.path.join(config["outdir"], "snps_only.contree") if config["snps_only"] else []
        
        
rule create_subset:
    input:
        focal = config["focal_list"],
        master_fasta = config["master_fasta"],
        background = config["background_list"] if config["background_list"] else []
    
    output: 
        sub_fasta = os.path.join(config["outdir"], "outbreak.fa")
     
    run: 
        if config["background_list"]:
            shell("""
            fastafurious subset -f {input.master_fasta} -l {input.focal} \
            -o {config[outdir]}/only_focal.fa
            
            fastafurious subset -f {input.master_fasta} -l {input.background} \
            -o {config[outdir]}/only_background.fa
            
            cat {config[outdir]}/only_focal.fa {config[outdir]}/only_background.fa > {output.sub_fasta}
            """)
        else:
            shell("""
            fastafurious subset -f {input.master_fasta} -l {input.focal} \
            -o {output.sub_fasta}
            """)
            
rule rename_headers: 
    input: 
        fasta = rules.create_subset.output.sub_fasta,
        names_csv = config["names_csv"] if config["names_csv"] else []
    output: 
        renamed = os.path.join(config["outdir"], "outbreak_renamed.fa")
    run: 
        if config["rename"]: 
            if config["names_csv"]: 
                shell("""
                fastafurious rename -i {input.fasta} -s {input.names_csv} \
                -1 original_name -2 new_name
                """)
            else:
                fasta_to_open = open(input.fasta)
                newfasta = open(output.renamed, 'w')
                for line in fasta_to_open: 
                    if line.startswith('>'):
                        line_cleaned = line.strip('>').strip()
                        replacement_name = "ON-PHL" + line_cleaned.split("PHLON")[1].split("-SARS")[0] + "-" + line_cleaned.split("PHLON")[1].split("-SARS")[1]
                        newfasta.write(">" + replacement_name + "\n")
                    else:
                        newfasta.write(line)
                
                fasta_to_open.close()
                newfasta.close()
 
                
if config["rename"]: 
    INPUT_ALIGN = rules.rename_headers.output.renamed
else:
    INPUT_ALIGN = rules.create_subset.output.sub_fasta
        

rule align:
    input: 
        reference = config["reference"],
        fasta = INPUT_ALIGN
    
    output: 
        alignment = os.path.join(config["outdir"], "outbreak_aln.fasta")
        
    shell: 
        """
        augur align --sequences {input.fasta} \
        --reference-sequence {input.reference} \
        --output {output.alignment} \
        --nthreads {config[nthreads]} \
        --fill-gaps
        """

rule tree: 
    input:
        alignment = rules.align.output.alignment
    
    output: 
        tree = os.path.join(config["outdir"], "tree.nwk")
    
    shell: 
        """
        augur tree --alignment {input.alignment} \
        --output {output.tree} \
        --nthreads {config[nthreads]}
        """

rule snps_only: 
    input: 
        alignment = rules.align.output.alignment
    output: 
        snps_only = os.path.join(config["outdir"], "snps_only.fasta")
    run: 
        if config["snps_only"]:
            shell("""
            snp-sites -m -c -o {output.snps_only} {input.alignment}
            """)


rule snps_only_tree: 
    input: 
        snps_fasta = rules.snps_only.output.snps_only
    output: 
        snps_only_tree = os.path.join(config["outdir"], "snps_only.contree")
    run: 
        if config["snps_only"]: 
            shell(
            """
            iqtree2 -alrt 1000 -bb 1000 -pre {config[outdir]}/snps_only -s {input.snps_fasta}
            """)
        


