.PHONY: all clean

SRC:=fake.c
EXE:=fake
BINARY:=fake.gz
CFLAGS:=-Os
LDFLAGS:=--static

all: $(BINARY)

$(BINARY): $(SRC) Makefile
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRC) -o $(EXE)
	strip $(EXE)
	gzip -f $(EXE)

clean:
	$(RM) -fv $(EXE) $(BINARY)
