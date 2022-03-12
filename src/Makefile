.PHONY : copy_additional build build-preview serve

ROOT_FILES := keybase.txt
ROOT_FILES_TARGETS := $(ROOT_FILES:%=$(DEST_DIR)/%)
TEMPLATES := zshrc.erb
TEMPLATES_TARGETS := $(TEMPLATES:%.erb=$(DEST_DIR)/%)


$(ROOT_FILES_TARGETS): $(ROOT_FILES)
	cp $< $@

$(TEMPLATES_TARGETS): $(TEMPLATES)
	echo $(ROOT_FILES_TARGETS)
	bundle exec ruby ../scripts/build_template.rb $(@:$(DEST_DIR)/%=%.erb) $@

build: $(ROOT_FILES_TARGETS) $(TEMPLATES_TARGETS)
	hugo -d "$(DEST_DIR)/ell"
	
build-preview: $(ROOT_FILES_TARGETS) $(TEMPLATES_TARGETS)
	hugo -D -d "$(DEST_DIR)/ell"

serve:
	hugo serve -D -F --disableFastRender
