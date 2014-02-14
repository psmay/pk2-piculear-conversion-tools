
BUILD=./build
PK2A=$(BUILD)/pk2dft-jsonhack
PK2ASRC=./pk2dft-jsonhack.c
DEVICEFILE=../PK2DeviceFile.dat
CA=$(BUILD)/combined-and-associated.json
DCA=./combine-and-associate.pl
DUMP_DIR=$(BUILD)/dump
DUMP_PART_NAMES=families devices scripts
DUMP_PART_DIRS=$(addprefix $(DUMP_DIR)/,$(DUMP_PART_NAMES))
DUMP_PART_FILES=$(addprefix $(BUILD)/,$(addsuffix .json.tmp,$(DUMP_PART_NAMES)))
DUMP=$(BUILD)/dump.json
CATARRAY=sh ./cat-array.sh
CATOBJECT=sh ./cat-object.sh
UNRELAX=perl ./unrelax-json.pl

default: $(CA)

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)

#
# Compile unpacker
#

$(PK2A): $(PK2ASRC) | $(BUILD)
	gcc $^ -lconfuse -o $@

#
# Dump data
#

$(DUMP_DIR): $(DEVICEFILE) $(PK2A) | $(BUILD)
	$(PK2A) -d $< $(DUMP_DIR)

#
# Consolidate dump data into single JSON
#

$(DUMP_PART_DIRS): $(DUMP_DIR)

$(DUMP_PART_FILES): $(BUILD)/%.json.tmp: $(DUMP_DIR)/%
	$(CATARRAY) $</*.* >$@

$(DUMP): $(DUMP_PART_FILES)
	$(CATOBJECT) $^ | $(UNRELAX) >$@


#
# Combine and associate script bytes
#

$(CA): $(DCA) $(DUMP)
	perl $(DCA) <$(DUMP) >$@
