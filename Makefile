# Directories
BINDIR   = build/bin
LIBDIR   = build/lib
OBJDIR   = build/obj
SRCDIR   = src
VAPIDIR  = vapi
BASEDIR  = examples

LIBS = "glib-2.0 gio-2.0 gee-0.8"
PKGCONFIG := $(shell pkg-config --cflags --libs $(LIBS))
CC = gcc
CFLAGS :=

.PHONY: all client clean commit-ready

all: lib client

lib: $(LIBDIR)/libhttp.so
client: $(BINDIR)/http-get

$(BINDIR)/%: $(BASEDIR)/%.vala | $(BINDIR)
	valac $< --pkg gee-0.8 --pkg gio-2.0 --pkg http -o $@ --vapidir=$(VAPIDIR) -X -I$(SRCDIR) -X -L$(LIBDIR) -X -lhttp

$(LIBDIR)/libhttp.so: $(OBJDIR)/http.o | $(LIBDIR)
	$(CC) -shared -o $@ $<

$(OBJDIR)/http.o: $(SRCDIR)/http.c | $(OBJDIR)
	$(CC) -c -fPIC $< $(PKGCONFIG) -o $@ -g

$(SRCDIR)/http.c: $(SRCDIR)/http.vala
	valac -C $< --pkg gee-0.8 --pkg gio-2.0 -H $(SRCDIR)/http.h --library $(VAPIDIR)/http

$(BINDIR):
	mkdir -p $(BINDIR)

$(LIBDIR):
	mkdir -p $(LIBDIR)

$(OBJDIR):
	mkdir -p $(OBJDIR)

clean:
	@$(RM) $(BINDIR)/* $(OBJDIR)/*.o $(VAPIDIR)/* $(SRCDIR)/*.c $(SRCDIR)/*.h $(LIBDIR)/*

