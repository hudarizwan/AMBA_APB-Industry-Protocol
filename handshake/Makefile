current_dir := ${CURDIR}

TOP := top

SOURCES := \
	${current_dir}/master.v \
	${current_dir}/slave.v \
	${current_dir}/top.v

ifeq ($(TARGET),arty_100)
  XDC := ${current_dir}/arty.xdc

else ifeq ($(TARGET),nexys4ddr)
  XDC := ${current_dir}/nexys4ddr.xdc

else ifeq ($(TARGET),zybo)
  XDC := ${current_dir}/zybo.xdc

else ifeq ($(TARGET),nexys_video)
  XDC := ${current_dir}/nexys_video.xdc

else ifeq ($(TARGET),basys3)
  XDC := ${current_dir}/basys3.xdc

endif

include ${current_dir}/../../common/common.mk
