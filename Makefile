
UNAME_S := $(shell uname -s 2>/dev/null || echo unknown)
UNAME_O := $(shell uname -o 2>/dev/null || echo unknown)

ifdef DEBUG
CFLAGS = -O0 -g -Wextra -DMEMDEBUG -DSTRBUF_CHECK
#LDFLAGS = -lefence
LDFLAGS += -g
else
CFLAGS = -O2
endif

ifdef NO_ICONV
CFLAGS += -DNO_ICONV
endif

LIBS = -lz
ZIP_OBJS =
ifdef HAVE_LIBZIP
	CFLAGS += -DHAVE_LIBZIP
	LIBS += -lzip
else
	ZIP_OBJS = kunzip/fileio.o kunzip/zipfile.o
endif

OBJ = odt2txt.o regex.o mem.o strbuf.o $(ZIP_OBJS)
TEST_OBJ = t/test-strbuf.o t/test-regex.o
ALL_OBJ = $(OBJ) $(TEST_OBJ)

INSTALL = install
GROFF   = groff

DESTDIR =
prefix  = /usr/local
bindir  = $(prefix)/bin
mandir  = $(prefix)/share/man
man1dir = $(mandir)/man1

ifeq ($(UNAME_S),FreeBSD)
	CFLAGS += -DICONV_CHAR="const char" -I/usr/local/include
	LDFLAGS += -L/usr/local/lib
	LIBS += -liconv
endif
ifeq ($(UNAME_S),OpenBSD)
	CFLAGS += -DICONV_CHAR="const char" -I/usr/local/include
	LDFLAGS += -L/usr/local/lib
	LIBS += -liconv
endif
ifeq ($(UNAME_S),Darwin)
       CFLAGS += -I/opt/local/include
       LDFLAGS += -L/opt/local/lib
       LIBS += -liconv
endif
ifeq ($(UNAME_S),NetBSD)
	CFLAGS += -DICONV_CHAR="const char"
endif
ifeq ($(UNAME_S),SunOS)
	ifeq ($(CC),cc)
		ifdef DEBUG
			CFLAGS = -v -g -DMEMDEBUG -DSTRBUF_CHECK
		else
			CFLAGS = -xO3
		endif
	endif
	CFLAGS += -DICONV_CHAR="const char"
endif
ifeq ($(UNAME_S),HP-UX)
	CFLAGS += -I$(ZLIB_DIR)
	LIBS = $(ZLIB_DIR)/libz.a
endif
ifeq ($(UNAME_O),Cygwin)
	CFLAGS += -DICONV_CHAR="const char"
	LIBS += -liconv
	EXT = .exe
endif
ifneq ($(MINGW32),)
	CFLAGS += -DICONV_CHAR="const char" -I$(REGEX_DIR) -I$(ZLIB_DIR)
	LIBS = $(REGEX_DIR)/regex.o
	ifdef STATIC
		LIBS += $(wildcard $(ICONV_DIR)/lib/.libs/*.o)
		LIBS += $(ZLIB_DIR)/zlib.a
	else
		LIBS += -liconv
	endif
	EXT = .exe
endif

BIN = odt2txt$(EXT)
MAN = odt2txt.1

$(BIN): $(OBJ)
	$(CC) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)

t/test-strbuf: t/test-strbuf.o strbuf.o mem.o
t/test-regex: t/test-regex.o regex.o strbuf.o mem.o

$(ALL_OBJ): Makefile

all: $(BIN)

install: $(BIN) $(MAN)
	$(INSTALL) -d -m755 $(DESTDIR)$(bindir)
	$(INSTALL) $(BIN) $(DESTDIR)$(bindir)/
	$(INSTALL) -d -m755 $(DESTDIR)$(man1dir)
	$(INSTALL) $(MAN) $(DESTDIR)$(man1dir)/

odt2txt.html: $(MAN)
	$(GROFF) -Thtml -man $(MAN) > $@

odt2txt.ps: $(MAN)
	$(GROFF) -Tps -man $(MAN) > $@

clean:
	rm -fr $(OBJ) $(BIN) odt2txt.ps odt2txt.html

.PHONY: clean

