GHC ?= ghc
GHC_VERSION := $(shell $(GHC) --version | awk '{print $$NF}')
RTS_LIB := HSrts-ghc$(GHC_VERSION)
CFLAGS := $(shell pkg-config r_core r_lang --cflags) -Wall -Werror
LDFLAGS := -l$(RTS_LIB)

all: lang_haskell.so

lang_haskell.o: lang_haskell.hs
	ghc $^ -dynamic -fPIC -c -o $@

lang_haskell.so: lang_haskell.o interface.c
	ghc -dynamic -fPIC -shared \
		-optc $(CFLAGS) \
		-optl $(LDFLAGS) -o $@ lang_haskell.o interface.c 

.PHONY: install reinstall clean 

install: lang_haskell.so
	cp $^ ~/.config/radare2/plugins

reinstall: clean install

clean:
	rm -f *.hi *.o *.so

