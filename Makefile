
BUILD=./build
PK2A=$(BUILD)/pk2dft-jsonhack
PK2ASRC=./pk2dft-jsonhack.c
DEVICEFILE=PK2DeviceFile.dat
CA=$(BUILD)/combined-and-associated.json
DCA=./combine-and-associate.pl
ST=$(BUILD)/script-command-table.json
DST=./script-command-table.pl
BA=$(BUILD)/with-simple-annotations.json
DBA=./simple-annotate.pl

# pk2dft dump
DUMP_DIR=$(BUILD)/dump
DUMP_PART_NAMES=families devices scripts
DUMP_PART_DIRS=$(addprefix $(DUMP_DIR)/,$(DUMP_PART_NAMES))
DUMP_PART_FILES=$(addprefix $(BUILD)/,$(addsuffix .json.tmp,$(DUMP_PART_NAMES)))
DUMP=$(BUILD)/dump.json

# JSON processing
CATARRAY=sh ./cat-array.sh
CATOBJECT=sh ./cat-object.sh
UNRELAX=perl ./unrelax-json.pl

default: $(BA)

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


#
# Convert an inline table of script commands and arguments into JSON
#

$(ST): $(DST) | $(BUILD)
	perl $(DST) > $(ST)

#
# Add human-readable names to ops and operands; apply adjustments to clarify meanings
#

$(BA): $(DBA) $(ST) $(CA) | $(BUILD)
	perl $(DBA) $(ST) <$(CA) >$@

