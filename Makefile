.PHONY: all clean

OS:=$(shell uname -o | xargs echo -n | tr -c 'A-Za-z0-9' '_' | tr 'A-Z' 'a-z')
ARCH:=$(shell uname -m | xargs echo -n | tr -c 'A-Za-z0-9' '_' | tr 'A-Z' 'a-z')
define assert
  $(if $1,,$(error Assertion failed: $2))
endef

$(call assert,$(findstring linux, $(OS)), This example only works with linux)

SRC:=fake.c
EXE:=fake
EXE_FULL:=$(EXE).$(ARCH)
BINARY:=$(EXE_FULL).gz
CFLAGS:=-Os
LDFLAGS:=--static

all: $(BINARY)

$(BINARY): $(SRC) Makefile
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRC) -o $(EXE_FULL)
	strip $(EXE_FULL)
	gzip -f $(EXE_FULL)

clean:
	$(RM) -fv $(EXE) $(EXE_FULL) $(BINARY)
