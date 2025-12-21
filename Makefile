.PHONY: clean

clean:
	find . -type d -name compiled -exec rm -rf {} + 2>/dev/null || true
