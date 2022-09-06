# Any of these can be changed, either in this file or just passed on
# the command line
export PREFIX=/Set_the_prefix_value
export ISISROOT=$(PREFIX)/isis
export ISISDATA=$(PREFIX)/isis_data
export AFIDSROOT=$(PREFIX)/afids
export POMMDATA=$(PREFIX)/pomm_data

# one command to do all 3 steps
install: $(ISISROOT) $(ISISDATA) $(AFIDSROOT) $(POMMDATA)

$(ISISROOT): isis-install-supplement
	cd $< && $(MAKE) -e install-isis

$(ISISDATA): isis-install-supplement
	cd $< && $(MAKE) -e install-isis-data install-mex-data

$(POMMDATA): pomm_data.tar.gz
	mkdir -p $(PREFIX)
	tar -xf $< -C $(PREFIX)

$(AFIDSROOT): afids-conda-package
	cd $< && $(MAKE) -e install-afids
	eval "$$($(AFIDSROOT)/bin/conda shell.bash hook)" && conda activate $(AFIDSROOT) && conda env config vars set AFIDS_PLANET_DEM=$(POMMDATA)/planet_dem AFIDS_PROJDEF=$(POMMDATA)/projdef
# We use pigz to create the data tar file, because otherwise this
# takes forever
pomm_data.tar.gz:
	tar -I pigz $@ ./pomm_data

temp: $(AFIDSROOT)
temp2: $(POMMDATA)
