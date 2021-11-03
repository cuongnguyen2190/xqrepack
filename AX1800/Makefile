FIRMWARES:=$(shell cd ax1800-orig-firmwares; ls *.bin | sed 's/\.bin$$//')

# TARGETS_TEST:=$(patsubst %,%+test.zip,$(FIRMWARES))
TARGETS_AX1800_SSH:=$(patsubst %,%+SSH.zip,$(FIRMWARES))
TARGETS_AX1800_SSH_MI:=$(patsubst %,%+SSH+MI.zip,$(FIRMWARES))
TARGETS_AX1800_SSH_MI_OPT:=$(patsubst %,%+SSH+MI+opt.zip,$(FIRMWARES))
TARGETS_AX1800_SSH_OPT:=$(patsubst %,%+SSH+opt.zip,$(FIRMWARES))
TARGETS:=$(shell echo $(TARGETS_AX1800_SSH) $(TARGETS_AX1800_SSH_MI) $(TARGETS_AX1800_SSH_MI_OPT) $(TARGETS_AX1800_SSH_OPT) | sed 's/ /\n/g' | sort)

# TARGETS:=$(shell echo $(TARGETS_AX1800_SSH_OPT) | sed 's/ /\n/g' | sort)

all: $(TARGETS)

%+SSH.zip: ax1800-orig-firmwares/%.bin ax1800-repack-squashfs.sh
	rm -f $@
	-rm -rf ubifs-root/$*.bin
	ubireader_extract_images -w ax1800-orig-firmwares/$*.bin
	fakeroot -- ./ax1800-repack-squashfs.sh ubifs-root/$*.bin/img-*_vol-ubi_rootfs.ubifs cuong.ga 1234567890
	./ax1800-ubinize.sh ubifs-root/$*.bin/img-*_vol-kernel.ubifs ubifs-root/$*.bin/img-*_vol-ubi_rootfs.ubifs.new --data
	zip -9 $@ r1800-raw-img.bin
	rm -f r1800-raw-img.bin

%+SSH+MI.zip: ax1800-orig-firmwares/%.bin ax1800-repack-squashfs-mi.sh
	rm -f $@
	-rm -rf ubifs-root/$*.bin
	ubireader_extract_images -w ax1800-orig-firmwares/$*.bin
	fakeroot -- ./ax1800-repack-squashfs-mi.sh ubifs-root/$*.bin/img-*_vol-ubi_rootfs.ubifs cuong.ga 1234567890
	./ax1800-ubinize.sh ubifs-root/$*.bin/img-*_vol-kernel.ubifs ubifs-root/$*.bin/img-*_vol-ubi_rootfs.ubifs.new --data
	zip -9 $@ r1800-raw-img.bin
	rm -f r1800-raw-img.bin

%+SSH+MI+opt.zip: ax1800-orig-firmwares/%.bin ax1800-repack-squashfs-mi-opt.sh
	rm -f $@
	-rm -rf ubifs-root/$*.bin
	ubireader_extract_images -w ax1800-orig-firmwares/$*.bin
	fakeroot -- ./ax1800-repack-squashfs-mi-opt.sh ubifs-root/$*.bin/img-*_vol-ubi_rootfs.ubifs cuong.ga 1234567890
	./ax1800-ubinize.sh ubifs-root/$*.bin/img-*_vol-kernel.ubifs ubifs-root/$*.bin/img-*_vol-ubi_rootfs.ubifs.new --data
	zip -9 $@ r1800-raw-img.bin
	rm -f r1800-raw-img.bin

%+SSH+opt.zip: ax1800-orig-firmwares/%.bin ax1800-repack-squashfs-opt.sh
	rm -f $@
	-rm -rf ubifs-root/$*.bin
	ubireader_extract_images -w ax1800-orig-firmwares/$*.bin
	fakeroot -- ./ax1800-repack-squashfs-opt.sh ubifs-root/$*.bin/img-*_vol-ubi_rootfs.ubifs cuong.ga 1234567890
	./ax1800-ubinize.sh ubifs-root/$*.bin/img-*_vol-kernel.ubifs ubifs-root/$*.bin/img-*_vol-ubi_rootfs.ubifs.new --data
	zip -9 $@ r1800-raw-img.bin
	rm -f r1800-raw-img.bin
