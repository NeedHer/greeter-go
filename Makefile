LIB_NAME     := greeter
LANGUAGE     := go
LANGUAGE_CAP := Go

SRC_DIR   := .
BUILD_DIR := build
OBJ_DIR   := $(BUILD_DIR)/obj
GOX_DIR   := $(BUILD_DIR)/gox

TARGET_TRIPLE := $(shell gcc -dumpmachine)

DESTDIR     ?= /usr/local
LIB_DIR     := lib
INCLUDE_DIR := include

GOCC      := gccgo
GOCCFLAGS := -O2 -g0 -fPIC -Wall -Wextra

VERSION_MAJOR := 1
VERSION_MINOR := 0
VERSION_PATCH := 0
VERSION       := $(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)

PKG_DIRS  := $(shell find . -type f -name "*.go" -exec dirname {} \; | sort -ur)
PKG_NAMES := $(subst .,$(LIB_NAME), $(PKG_DIRS))
PKG_OBJS  := $(addprefix $(OBJ_DIR)/, $(addsuffix .o, $(PKG_NAMES)))
PKG_GOXS  := $(addprefix $(GOX_DIR)/, $(addsuffix .gox, $(PKG_NAMES)))

PKG_GO_DIR  = $(if $(filter $(LIB_NAME),$*),.,$(patsubst $(LIB_NAME)/%,%,$*))
PKG_GO_SRCS = $(filter-out %_test.go, $(wildcard $(PKG_GO_DIR)/*.go))

EXPORT_DIR        := $(GOX_DIR)/$(LIB_NAME)
STATIC_LIB        := lib$(LIB_NAME)-$(LANGUAGE).a
SHARED_LIB        := lib$(LIB_NAME)-$(LANGUAGE).so
SHARED_LIB_FULL   := lib$(LIB_NAME)-$(LANGUAGE).so.$(VERSION)
SHARED_LIB_SONAME := lib$(LIB_NAME)-$(LANGUAGE).so.$(VERSION_MAJOR)

.PHONY: all clean install uninstall format

$(LIB_NAME)-$(LANGUAGE): 
	@$(MAKE) --no-print-directory go-export go-static-lib go-shared-lib

go-export: $(PKG_GOXS)
go-static-lib: $(STATIC_LIB)
go-shared-lib: $(SHARED_LIB)

$(OBJ_DIR)/%.o: 
	@mkdir -p $(dir $@)
	$(GOCC) $(GOCCFLAGS) -fgo-pkgpath=$* -c $(PKG_GO_SRCS) -o $@

$(GOX_DIR)/%.gox: $(OBJ_DIR)/%.o
	@mkdir -p $(dir $@)
	objcopy -j .go_export $< $@

$(STATIC_LIB): $(PKG_OBJS)
	ar rcs $@ $^

$(SHARED_LIB_FULL): $(PKG_OBJS)
	$(GOCC) -shared -Wl,-soname,$(SHARED_LIB_SONAME) -o $@ $^

$(SHARED_LIB): $(SHARED_LIB_FULL)
	ln -sf $(SHARED_LIB_FULL) $(SHARED_LIB)
	ln -sf $(SHARED_LIB_FULL) $(SHARED_LIB_SONAME)

clean:
	rm -rf $(BUILD_DIR) $(STATIC_LIB) $(SHARED_LIB) $(SHARED_LIB_FULL) $(SHARED_LIB_SONAME)

install: $(LIB_NAME)-$(LANGUAGE)
	install -d $(DESTDIR)/$(INCLUDE_DIR)/$(LANGUAGE)
	cp -a $(EXPORT_DIR)/* $(DESTDIR)/$(INCLUDE_DIR)/$(LANGUAGE)
	install -d $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE)
	install -m 644 $(STATIC_LIB) $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE)
	install -m 755 $(SHARED_LIB_FULL) $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE)
	ln -sf $(SHARED_LIB_FULL) $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE)/$(SHARED_LIB_SONAME)
	ln -sf $(SHARED_LIB_FULL) $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE)/$(SHARED_LIB)

uninstall:
	rm -f $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE)/$(STATIC_LIB)
	rm -f $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE)/$(SHARED_LIB)
	rm -f $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE)/$(SHARED_LIB_SONAME)
	rm -f $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE)/$(SHARED_LIB_FULL)
	rm -rf $(DESTDIR)/$(INCLUDE_DIR)/$(LANGUAGE)/$(LIB_NAME)
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/$(INCLUDE_DIR)/$(LANGUAGE)|| true
	rmdir --ignore-fail-on-non-empty $(DESTDIR)/$(LIB_DIR)/$(TARGET_TRIPLE) || true

format:
	go fmt $(shell find $(SRC_DIR) -name '*.go')
