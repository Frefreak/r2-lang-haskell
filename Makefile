GHC ?= stack exec -- ghc
GHC_VERSION := $(shell $(GHC) --version | awk '{print $$NF}')
RTS_LIB := HSrts-ghc$(GHC_VERSION)
CFLAGS := $(shell pkg-config r_core r_lang --cflags) -Wall -Werror
LDFLAGS := -l$(RTS_LIB)

all: lang_haskell.so

lang_haskell_stub.h: lang_haskell.hs
	$(GHC) -c $^

lang_haskell.so: lang_haskell_stub.h lang_haskell.hs interface.c
	$(GHC) -dynamic -fPIC -shared $(CFLAGS) $(LDFLAGS) -o $@ \
		-threaded $(filter-out $<, $^)

.PHONY: install reinstall clean

install: lang_haskell.so
	cp $^ ~/.config/radare2/plugins

reinstall: clean install

clean:
	rm -f *.hi *.o *.so

