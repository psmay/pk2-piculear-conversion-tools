
BUILD=./build
PK2A=$(BUILD)/pk2dft-jsonhack
PK2ASRC=./pk2dft-jsonhack.c
DEVICEFILE=../PK2DeviceFile.dat
CA=$(BUILD)/combined-and-associated.json
DCA=./combine-and-associate.pl
DUMP=$(BUILD)/dump
CORPUS=$(BUILD)/script-corpus.txt

default: $(CA)

$(BUILD):
	mkdir -p $@

clean:
	rm -rf $(BUILD)

$(PK2A): $(PK2ASRC) | $(BUILD)
	gcc $^ -lconfuse -o $@

$(DUMP): $(DEVICEFILE) $(PK2A) | $(BUILD)
	$(PK2A) -d $< $(DUMP)

$(CORPUS): $(DUMP) | $(BUILD)
	find $(DUMP)/scripts -type f -name '*.scr' -print0 | \
	xargs -0 -i -n 1 basename {} .scr | \
	sort > $@

$(CA): $(DCA) $(CORPUS) $(DUMP)
	echo "[" >$@.tmp
	cat $(CORPUS) | \
	perl -n -e 'chomp; print "$$_\0";' | \
	xargs -0 -i perl $< $(DUMP)/'scripts/{}.scr' >>$@.tmp
	echo ' ]' >>$@.tmp
	perl unrelax-json.pl <$@.tmp >$@
	rm -f $@.tmp
