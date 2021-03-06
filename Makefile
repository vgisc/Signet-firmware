all: signet-fw serial-loader dfu-util-loader json-encoder

BTUPLE:=$(shell echo $(shell ./config.guess) | sed -e 's/\([a-z_09A-Z]\)*-/\1-build_/')
HTUPLE:=arm-none-eabi

LIBBDF_INSTALLDIR=$(HOME)/x-tools/$(HTUPLE)/$(BTUPLE)

SERIAL_LOADER_LDFLAGS=-L$(LIBBDF_INSTALLDIR)/lib
SERIAL_LOADER_INCLUDES=-I$(LIBBDF_INSTALLDIR)/include
SERIAL_LOADER_LIBS=-lbfd -lz -ldl
SERIAL_LOADER_CPPFLAGS=-DPACKAGE

serial-loader: serial-loader.c
	gcc $< $(SERIAL_LOADER_LDFLAGS) $(SERIAL_LOADER_INCLUDES) $(SERIAL_LOADER_CPPFLAGS) $(SERIAL_LOADER_LIBS) -o $@

JSON_ENCODER_LDFLAGS=-L$(LIBBDF_INSTALLDIR)/lib
JSON_ENCODER_INCLUDES=-I$(LIBBDF_INSTALLDIR)/include -Ilibb64-1.2.1/include
JSON_ENCODER_LIBS=-lbfd -lz -ldl -ljson-c libb64-1.2.1/src/libb64.a
JSON_ENCODER_CPPFLAGS=-DPACKAGE

json-encoder: json-encoder.c
	gcc $< $(JSON_ENCODER_LDFLAGS) $(JSON_ENCODER_INCLUDES) $(JSON_ENCODER_CPPFLAGS) $(JSON_ENCODER_LIBS) -o $@

DFU_UTIL_LOADER_LDFLAGS=-L$(LIBBDF_INSTALLDIR)/lib
DFU_UTIL_LOADER_INCLUDES=-I$(LIBBDF_INSTALLDIR)/include
DFU_UTIL_LOADER_LIBS=-lbfd -lz -ldl
DFU_UTIL_LOADER_CPPFLAGS=-DPACKAGE

dfu-util-loader: dfu-util-loader.c
	gcc $< $(DFU_UTIL_LOADER_LDFLAGS) $(DFU_UTIL_LOADER_INCLUDES) $(DFU_UTIL_LOADER_CPPFLAGS) $(DFU_UTIL_LOADER_LIBS) -o $@

LIBS=-lnettle
CFLAGS=-mcpu=cortex-m4 -mthumb -ffunction-sections -fdata-sections -O2
LDFLAGS=-Wl,"--gc-sections" -nostdlib

CFLAGS+= -DFIRMWARE -Wall

LDFLAGS+= -Wl,"-Tstm32l443xc.ld"

CFLAGS += -DUSE_RAW_HID -I../signet-desktop-client/common

clean:
	rm -rf *.o *.d signet-fw serial-loader json-encoder dfu-util-loader

%.o: %.c
	$(HTUPLE)-gcc  $(CFLAGS) $< -c -o $@
	@$(HTUPLE)-gcc  $(CFLAGS) $< -M -MF $@.d

MCU_SOURCES = ivt_l443xc.c main_l443xc.c rng_driver.c flash_l443xc.c

SOURCES = startup.c firmware_update_state.c commands.c crc.c db.c \
	  usb_fs_driver.c \
	  usart.c stm_aes.c usb_serial.c usb_storage.c usb.c usb_keyboard.c \
	  print.c mem.c irq.c gpio.c rtc_rand.c \
	  usb_raw_hid.c $(MCU_SOURCES)

OBJECTS = $(SOURCES:.c=.o)
DEPFILES = $(SOURCES:.c=.o.d)

signet-fw: $(OBJECTS)
	$(HTUPLE)-gcc  $(CFLAGS) $(LDFLAGS) $^ $(LIBS) -o $@

-include $(DEPFILES)
