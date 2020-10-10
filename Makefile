PWD:=$(shell pwd)

ifndef KVERS
  KVERS:=$(shell uname -r)
endif

ifndef KSRC
  ifneq (,$(wildcard /lib/modules/$(KVERS)/build))
    KSRC:=/lib/modules/$(KVERS)/build
  else
    KSRC_SEARCH_PATH:=/usr/src/linux
    KSRC:=$(shell for dir in $(KSRC_SEARCH_PATH); do if [ -d $$dir ]; then echo $$dir; break; fi; done)
  endif
endif

KVERS_MAJ:=$(shell echo $(KVERS) | cut -d. -f1-2)
KINCLUDES:=$(KSRC)/include

KCONFIG:=$(KSRC)/.config
ifneq (,$(wildcard $(KCONFIG)))
  HAS_KSRC:=yes
  include $(KCONFIG)
else
  HAS_KSRC=no
endif

KMAKE=+$(MAKE) -C $(KSRC) M=$(PWD)/drivers/epiphany

all: modules

modules:
ifeq (no,$(HAS_KSRC))
	@echo "You do not appear to have the sources for the $(KVERS) kernel installed."
	@exit 1
endif
	$(KMAKE) modules

install: all install-modules
	@echo "Epiphany module installed successfully."

uninstall: uninstall-modules
	@echo "Epiphany module uninstalled successfully."

install-modules: modules
ifndef DESTDIR
	build_tools/uninstall-modules epiphany $(KVERS)
endif
	$(KMAKE) INSTALL_MOD_PATH=$(DESTDIR) INSTALL_MOD_DIR=epiphany modules_install
	[ `id -u` = 0 ] && /sbin/depmod -a $(KVERS) || :

uninstall-modules:
ifdef DESTDIR
	@echo "Uninstalling modules is not supported with a DESTDIR specified."
	@exit 1
else
	@if modinfo epiphany > /dev/null 2>&1 ; then \
		echo -n "Removing Epiphany modules for kernel $(KVERS), please wait..."; \
		build_tools/uninstall-modules epiphany $(KVERS); \
		rm -rf /lib/modules/$(KVERS)/epiphany; \
		echo "done."; \
	fi
	[ `id -u` = 0 ] && /sbin/depmod -a $(KVERS) || :
endif

clean:
ifneq (no,$(HAS_KSRC))
	$(KMAKE) clean
endif

.PHONY: all clean modules install-modules uninstall-modules

FORCE:

