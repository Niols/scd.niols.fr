.PHONY: build clean publish

build: clean
	@sh src/build.sh

clean:
	@rm -rf build

publish: build
	@printf 'publishing... '
	@rsync -a build scd@sechs.niols.fr:~/public_html
	@printf 'done\n'
