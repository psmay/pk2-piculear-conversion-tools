
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
CORPUS=$(BUILD)/script-corpus.txt
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
# Parts that should be reengineered
#

$(CORPUS): $(DUMP_DIR) | $(BUILD)
	find $(DUMP_DIR)/scripts -type f -name '*.scr' -print0 | \
	xargs -0 -i -n 1 basename {} .scr | \
	sort > $@

$(CA): $(DCA) $(CORPUS) $(DUMP_DIR)
	echo "[" >$@.tmp
	cat $(CORPUS) | \
	perl -n -e 'chomp; print "$$_\0";' | \
	xargs -0 -i perl $< $(DUMP_DIR)/'scripts/{}.scr' >>$@.tmp
	echo ' ]' >>$@.tmp
	$(UNRELAX) <$@.tmp >$@
	rm -f $@.tmp
