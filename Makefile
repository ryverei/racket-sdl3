.PHONY: clean doc check-docs

clean:
	find . -type d -name compiled -exec rm -rf {} + 2>/dev/null || true
	rm -rf doc

doc:
	mkdir -p doc
	PLTCOLLECTS="$(PWD):" /opt/homebrew/bin/raco scribble --html +m --redirect-main https://docs.racket-lang.org/ --dest doc scribblings/sdl3.scrbl

check-docs:
	PLTCOLLECTS="$(PWD):" racket scripts/check-docs.rkt
