# Copyright (C) 2017-2020  The SymbiFlow Authors.
#
# Use of this source code is governed by a ISC-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/ISC
#
# SPDX-License-Identifier: ISC
all::
	@true

# ------------------- FRONTEND ------------------

venv/bin/activate:
	virtualenv -p python3 venv

venv/bin/nodeenv: venv/bin/activate
	bash -c '. $< ; pip3 install nodeenv'

nenv/bin/activate: venv/bin/nodeenv
	bash -c '. venv/bin/activate ; nodeenv nenv'

nenv/bin/vue: nenv/bin/activate
	bash -c ' \
		. venv/bin/activate ; \
		. nenv/bin/activate ; \
		npm install -g \
			@vue/cli \
			@vue/cli-service-global ; \
		npm install \
			apexcharts vue-apexcharts vue-good-table ; \
	' && touch $@

dist/index.html: nenv/bin/vue App.vue Popup.vue Grid.vue Bitstream.vue bitstreamData.json
	bash -c ' \
		. venv/bin/activate ; \
		. nenv/bin/activate ; \
		NODE_ENV=development NODE_OPTIONS="--max_old_space_size=8192" vue build App.vue ; \
	'

all:: dist/index.html

clean::
	rm -rf dist frames grid

# -------------------- BACKEND --------------------

PRJXRAY  ?= ..
PART ?= xc7a35tcsg324-1
DATABASE = $(PRJXRAY)/database/artix7

bitstream.bits: $(BITSTREAM)
	$(PRJXRAY)/build/tools/bitread \
		--part_file $(DATABASE)/$(PART)/part.yaml \
		-o $@ -z -y $<

bitstream.frames: $(BITSTREAM)
	$(PRJXRAY)/build/tools/bitread \
		--part_file $(DATABASE)/$(PART)/part.yaml \
		-o $@ $<

bitstream.html: bitstream.frames bitstream.bits
	PYTHONPATH="$(PRJXRAY):$(PRJXRAY)/third_party/fasm:" \
		./bithtml.py \
		--db-dir=$(DATABASE) \
		--db-part=$(PART) \
		--frames-per-line=100 \
		--frames=bitstream.frames --bits=bitstream.bits --html=bitstream.html

frames/.dir:
	mkdir frames && touch $@

grid/.dir:
	mkdir grid && touch $@

bitstreamData.json: bitstream.bits bithtml.py grid/.dir frames/.dir
	PYTHONPATH="$(PRJXRAY):$(PRJXRAY)/third_party/fasm:" \
		./bithtml.py \
		--db-dir=$(DATABASE) \
		--db-part=$(PART) \
		--bits=bitstream.bits \
		--dump-grid=$@ --grid-dir=$$PWD/grid

clean::
	rm -f bitstream.frames bitstream.bits bitstream.html bitstreamData.json
