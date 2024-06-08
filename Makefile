# Any of these can be changed, either in this file or just passed on
# the command line
export PREFIX=/Set_the_prefix_value
export ISISROOT=$(PREFIX)/isis
export ISISDATA=$(PREFIX)/isis_data
export AFIDSROOT=$(PREFIX)/afids
export POMMDATA=$(PREFIX)/pomm_data

# DOCKER has some weird permission issues I don't understand. We may
# eventually sort this out, but for now just skip setting owner and group
# if we are in docker
ifdef IN_DOCKER
TAR_ARG=--no-same-owner
else
TAR_ARG=
endif

# one command to do all 3 steps
install: $(ISISROOT) $(ISISDATA) $(AFIDSROOT) $(POMMDATA)

$(ISISROOT): isis-install-supplement
	cd $< && $(MAKE) -e install-isis

$(ISISDATA): isis-install-supplement
	cd $< && $(MAKE) -e install-isis-data install-mex-data

$(POMMDATA):
	@test -s ./pomm_data.tar.gz || echo "pomm_data.tar.gz is too large to stage on the public github. You can request this file separately - it is publicly available but too large to stage. You only need it to test/work with Mars or Lunar data. If you get a copy, just place in this directory and either reinstall or just tar this yourself 'tar -I pigz $(TAR_ARG) -xf $< -C $(PREFIX)'"
	mkdir -p $(PREFIX)
	-tar -I pigz $(TAR_ARG) -xf $< -C $(PREFIX)

# We can't use git-lfs in public version without paying, and I don't want to try to figure
# out how to get JPL to pay for this. So instead, we use conda constructor to make a
# stand alone installation, and then put this as a resource in our release tag.
#$(AFIDSROOT): afids-conda-package
#	cd $< && $(MAKE) -e install-afids
#	eval "$$($(AFIDSROOT)/bin/conda shell.bash hook)" && conda activate $(AFIDSROOT) && conda env config vars set AFIDS_PLANET_DEM=$(POMMDATA)/planet_dem AFIDS_PROJDEF=$(POMMDATA)/projdef POMM_TESTCASE=$(POMMDATA)/testcases
#	cp $(AFIDSROOT)/afids/pommos/POMM_AFIDS_User_Guide*.pdf $(PREFIX)
#	cd $(AFIDSROOT); ln -s afids/pommos .
#	sed "s/ISIS/DONT_SETME/g" -i $(AFIDSROOT)/etc/afids/setup_afids_python.sh
#	sed "s/ISIS/DONT_SETME/g" -i $(AFIDSROOT)/etc/afids/setup_afids_python.csh

$(AFIDSROOT): 
	curl -L -o afids-20240415-Linux-x86_64.sh https://github.com/Cartography-jpl/pomm-delivery/releases/download/v1.0/afids-20240415-Linux-x86_64.sh
	bash afids-20240415-Linux-x86_64.sh -p $(AFIDSROOT) -b
	bash -c "eval '$$($(AFIDSROOT)/bin/conda shell.bash hook)' && conda activate $(AFIDSROOT) && conda env config vars set AFIDS_PLANET_DEM=$(POMMDATA)/planet_dem AFIDS_PROJDEF=$(POMMDATA)/projdef POMM_TESTCASE=$(POMMDATA)/testcases ISISROOT=$(ISISROOT) ISISDATA=$(ISISDATA)"
	cp $(AFIDSROOT)/afids/pommos/POMM_AFIDS_User_Guide*.pdf $(PREFIX)
	cd $(AFIDSROOT); ln -s afids/pommos .
	sed "s/ISIS/DONT_SETME/g" -i $(AFIDSROOT)/etc/afids/setup_afids_python.sh
	sed "s/ISIS/DONT_SETME/g" -i $(AFIDSROOT)/etc/afids/setup_afids_python.csh

# We use pigz to create the data tar file, because otherwise this
# takes forever
pomm_data.tar.gz:
	tar -I pigz -cf $@ ./pomm_data

# Build in docker, to make a clean test of everything.
# Note that the docker instance actually gets created in afids-conda-package,
# which just use the same one. This is just a oracle 8 instance, with
# various packages that conda assumes are available installed.
DOCKER_BASE_VERSION=1.0
DOCKER_POMM_VERSION=1.0

#DOCKER_NAME=docker-base
DOCKER_NAME=pomm-base

# If we have a failure and want to start with a new container, this
# stops the old one and removes the docker_run.id file
docker-cleanup:
	docker container stop $$(cat docker_run.id)
	rm docker_run.id

# Rule to start a interactive docker instance, just so I don't need to
# remember the syntax
docker-start:
	docker run -it -v $$(pwd):/home/afids-conda/workdir:Z afids-conda-package/$(DOCKER_NAME):$(DOCKER_BASE_VERSION) /bin/bash

# Rule to start a interactive docker instance with x11, just so I don't need to
# remember the syntax
docker-start-x11:
	docker run -e DISPLAY -it -v $$(pwd):/home/afids-conda/workdir:Z -v /tmp/.X11-unix:/tmp/.X11-unix --security-opt label=type:container_runtime_t --volume="$$HOME/.Xauthority:/root/.Xauthority:rw" --net=host afids-conda-package/$(DOCKER_NAME):$(DOCKER_BASE_VERSION) /bin/bash

# When a failure occurs, can connect to the docker instance used in a rule
docker-connect:
	docker exec -it $$(cat docker_run.id) bash --login

# Note, make sure we have run chcon -Rt svirt_sandbox_file_t on this
# directory (as root). This gives the proper permissions for docker to
# run
docker-full-test:
	-rm -rf install_docker
	cd afids-conda-package && git clean -f -d -x
	cd isis-install-supplement && git clean -f -d -x
	docker run -t -d --cidfile=docker_run.id -v $$(pwd):/home/afids-conda/workdir:Z afids-conda-package/docker-base:$(DOCKER_BASE_VERSION) /bin/bash
	docker exec $$(cat docker_run.id) bash --login -c "dnf install -y libXcomposite libXcursor libXi libXtst libXrandr alsa-lib mesa-libEGL libXdamage mesa-libGL libXScrnSaver"
# Also seem to need these packages
	docker exec $$(cat docker_run.id) bash --login -c "dnf install -y libICE ocl-icd libSM libquadmath pciutils-libs tbb xcb-util-renderutil xcb-util-wm xcb-util-image xcb-util-keysyms make bzip2 rsync pigz"
	docker exec $$(cat docker_run.id) bash --login -c "cd /home/afids-conda/workdir && make PREFIX=/home/afids-conda/workdir/install_docker IN_DOCKER=t install"
	docker exec $$(cat docker_run.id) bash --login -c "cd /home/afids-conda/workdir && source install_docker/afids/setup_afids_env.sh && cd /home/afids-conda/workdir/install_docker/pomm_data/testcases/coreg && vicarb 'runtop_nest nestst' 2>&1 | tee /home/afids-conda/workdir/install_docker/pomm_data/testcases/coreg/xxlog.log"
	docker exec $$(cat docker_run.id) bash --login -c "cd /home/afids-conda/workdir && source install_docker/afids/setup_afids_env.sh && cd /home/afids-conda/workdir/install_docker/pomm_data/testcases/mos_hrsc && vicarb 'runtop_pom hrsctst_mos' 2>&1 | tee /home/afids-conda/workdir/install_docker/pomm_data/testcases/mos_hrsc/xxlog.log"
	docker exec $$(cat docker_run.id) bash --login -c "cd /home/afids-conda/workdir && source install_docker/afids/setup_afids_env.sh && cd /home/afids-conda/workdir/install_docker/pomm_data/testcases/map_tst && vicarb 'runtop_map map_hirise' 2>&1 | tee /home/afids-conda/workdir/install_docker/pomm_data/testcases/map_tst/xxlog.log"
	docker commit $$(cat docker_run.id) afids-conda-package/pomm-base:$(DOCKER_POMM_VERSION)
	cd afids-conda-package && git clean -f -d -x
	cd isis-install-supplement && git clean -f -d -x
	docker container stop $$(cat docker_run.id)
	rm docker_run.id

# Additional tests, not in delivery documents but tests Tom runs
additional_test: additional_test_hirise_map additional_test_hrsc_map additional_test_nac_map

additional_test_hirise_map:
	source $(AFIDSROOT)/setup_afids_env.sh && cd $(POMMDATA)/additional_testcases/hirise_map && vicarb "../runtop_map pommui_mapproject"

additional_test_hrsc_map:
	source $(AFIDSROOT)/setup_afids_env.sh && cd $(POMMDATA)/additional_testcases/hrsc_map && vicarb "../runtop_map pommui_mapproject"

additional_test_nac_map:
	source $(AFIDSROOT)/setup_afids_env.sh && cd $(POMMDATA)/additional_testcases/nac_map && vicarb "../runtop_map raw2map_nac"
