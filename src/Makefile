.PHONY : copy_additional build build-preview serve

build:
	hugo -d "../${DEST_DIR}/ell"
	cp keybase.txt ../${DEST_DIR}
build-preview:
	hugo -D -d "../${DEST_DIR}/ell"
	cp keybase.txt ../${DEST_DIR}
serve:
	hugo serve -D -F --disableFastRender