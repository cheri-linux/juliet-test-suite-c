TARGET=Juliet1.3

# Bins
MAKE=make
CXX=g++
CFLAGS=-g
LDFLAGS=-lpthread

# Support files
SUPPORT_PATH=testcasesupport/
INCLUDES=$(SUPPORT_PATH)
SUPPORT_SRCS=$(addprefix $(SUPPORT_PATH),main_linux.cpp io.c std_thread.c)
SUPPORT_OBJS=$(addsuffix .o,$(SUPPORT_SRCS))

BIN_DIR?=$(shell pwd)/bin
export BIN_DIR
export TOP_BIN_DIR=$(BIN_DIR)

# Partial files
MAKE_FILES=$(wildcard testcases/*/s*/Makefile) $(wildcard testcases/*/Makefile)
PARTIALS=$(patsubst %Makefile,%partial,$(MAKE_FILES))
INDIVIDUALS=$(patsubst %Makefile,%individuals,$(MAKE_FILES))

# Suffixes individual
CWE_DIRS=$(wildcard testcases/*)
CWES=$(patsubst testcases/%,%,$(CWE_DIRS))
CWES_GOOD=$(addsuffix -good,$(CWES))
CWES_BAD=$(addsuffix -bad,$(CWES))
CWE_BIN_DIRS=$(addsuffix -dir, $(CWES))

CWE_CLEAN=$(addsuffix /clean,$(CWE_DIRS))

echo:
	@echo $(CWE_BIN_DIRS)


$(TARGET): $(PARTIALS) $(SUPPORT_OBJS)
	$(CXX) $(CFLAGS) -I $(INCLUDES) -o $(BIN_DIR)$@ $(addsuffix .o,$(PARTIALS)) $(SUPPORT_OBJS) $(LDFLAGS)

$(PARTIALS):
	$(MAKE) -C $(dir $@) $(notdir $@).o

bin-dir:
	@mkdir -p $(BIN_DIR)

support-lib: bin-dir
	$(MAKE) -C $(SUPPORT_PATH) support-lib

individuals: $(INDIVIDUALS)

$(INDIVIDUALS):
	$(MAKE) -C $(dir $@) $(notdir $@)

$(SUPPORT_OBJS): $(SUPPORT_SRCS)
	$(CXX) $(CFLAGS) -c -I $(INCLUDES) -o $@ $(@:.o=) $(LDFLAGS)


$(CWES): %: %-dir %-good %-bad

$(CWES_GOOD): support-lib
	$(MAKE) -C $(addprefix testcases/,$(patsubst %-good,%,$(@)))  -e BIN_DIR=$(BIN_DIR)/$(patsubst %-good,%,$@)/good -e CPPFLAGS="-DOMITBAD -DINCLUDEMAIN" individuals

$(CWES_BAD): support-lib
	$(MAKE) -C $(addprefix testcases/,$(patsubst %-bad,%,$(@))) -e BIN_DIR=$(BIN_DIR)/$(patsubst %-bad,%,$@)/bad -e CPPFLAGS="-DOMITGOOD -DINCLUDEMAIN" individuals

$(CWE_BIN_DIRS):
	@mkdir -p $(BIN_DIR)/$(patsubst %-dir,%,$(@))
	@mkdir -p $(BIN_DIR)/$(patsubst %-dir,%,$(@))/good
	@mkdir -p $(BIN_DIR)/$(patsubst %-dir,%,$(@))/bad


clean: $(CWE_CLEAN)
	$(MAKE) -C $(SUPPORT_PATH) clean
	@echo $(MAKE) -C testcases/*/s*/ clean
	@echo $(MAKE) -C testcases/*/ clean
	rm -rf $(BIN_DIR)*

$(CWE_CLEAN):
	$(MAKE) -C $(dir $@) $(notdir $@)
