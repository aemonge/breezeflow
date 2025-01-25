# Define the input and output files
QMD_FILE = readme.qmd
MD_FILE = README.md

# Target to render the .qmd file into a .md file
$(MD_FILE): $(QMD_FILE)
	pandoc readme.qmd -o README.md

# Phony target to clean up generated files
.PHONY: clean
clean:
	rm -f $(MD_FILE)
