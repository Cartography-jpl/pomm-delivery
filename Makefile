# Any of these can be changed, either in this file or just passed on
# the command line
export PREFIX=/Set_the_prefix_value
export ISISROOT=$(PREFIX)/isis
export ISISDATA=$(PREFIX)/isis_data
export AFIDSROOT=$(PREFIX)/afids

# one command to do all 3 steps
install: $(ISISROOT) $(ISISDATA) $(AFIDSROOT)

$(ISISROOT): isis-install-supplement
	cd $< && $(MAKE) -e install-isis

$(ISISDATA): isis-install-supplement
	cd $< && $(MAKE) -e install-isis-data install-mex-data

$(AFIDSROOT): afids-conda-package
	cd $< && $(MAKE) -e install-afids

temp: $(AFIDSROOT)
