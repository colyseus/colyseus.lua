default: none

none:
	$(error "To publish the package, run `make publish`")

publish:
	rm ~/*.rockspec
	./publish
	luarocks upload ~/*.rockspec


