# Define the input and output files
QMD_FILE = breezeflow.qmd
MD_FILE = README.md

# Target to render the .qmd file into a .md file
$(MD_FILE): $(QMD_FILE)
	quarto render $(QMD_FILE) --to gfm+yaml_metadata_block --output $(MD_FILE)

# Phony target to clean up generated files
.PHONY: clean
clean:
	rm -f $(MD_FILE)
