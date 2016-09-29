# cython: c_string_type=unicode, c_string_encoding=ascii
#-
# Copyright (c) 2015 iXsystems, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

cimport defs
import enum
import os
from posix.ioctl cimport ioctl
from libc.errno cimport errno
from libc.string cimport memset
from libc.stdlib cimport malloc, free
from libc.stdint cimport *


class EnclosureElementType(enum.IntEnum):
    UNSPECIFIED = defs.ELMTYP_UNSPECIFIED
    DEVICE = defs.ELMTYP_DEVICE
    POWER = defs.ELMTYP_POWER
    FAN = defs.ELMTYP_FAN
    THERM = defs.ELMTYP_THERM
    DOORLOCK = defs.ELMTYP_DOORLOCK
    ALARM = defs.ELMTYP_ALARM
    ESCC = defs.ELMTYP_ESCC
    SCC = defs.ELMTYP_SCC
    NVRAM = defs.ELMTYP_NVRAM
    INV_OP_REASON = defs.ELMTYP_INV_OP_REASON
    UPS = defs.ELMTYP_UPS
    DISPLAY = defs.ELMTYP_DISPLAY
    KEYPAD = defs.ELMTYP_KEYPAD
    ENCLOSURE = defs.ELMTYP_ENCLOSURE
    SCSIXVR = defs.ELMTYP_SCSIXVR
    LANGUAGE = defs.ELMTYP_LANGUAGE
    COMPORT = defs.ELMTYP_COMPORT
    VOM = defs.ELMTYP_VOM
    AMMETER = defs.ELMTYP_AMMETER
    SCSI_TGT = defs.ELMTYP_SCSI_TGT
    SCSI_INI = defs.ELMTYP_SCSI_INI
    SUBENC = defs.ELMTYP_SUBENC
    ARRAY_DEV = defs.ELMTYP_ARRAY_DEV
    SAS_EXP = defs.ELMTYP_SAS_EXP
    SAS_CONN = defs.ELMTYP_SAS_CONN


cdef class CamCCB(object):
    cdef CamDevice device
    cdef defs.ccb *ccb

    def __init__(self, CamDevice device):
        self.device = device

    def scsi_read_write(self, **kwargs):
        pass

    def send(self):
        pass


cdef class CamDevice(object):
    cdef defs.cam_device* dev

    def __init__(self, path):
        self.dev = defs.cam_open_device(path, defs.O_RDWR)
        if self.dev == NULL:
            raise RuntimeError('Cannot open device')

    def __dealloc__(self):
        if self.dev != NULL:
            defs.cam_close_device(self.dev)

    def __getstate__(self):
        return {
            'controller_name': self.controller_name,
            'controller_unit': self.controller_unit,
            'bus_id': self.bus_id,
            'target_id': self.target_id,
            'target_lun': self.target_lun,
            'path_id': self.path_id,
            'serial': self.serial
        }

    property bus_id:
        def __get__(self):
            return self.dev.bus_id

    property controller_name:
        def __get__(self):
            return self.dev.sim_name

    property controller_unit:
        def __get__(self):
            return self.dev.sim_unit_number

    property target_lun:
        def __get__(self):
            return self.dev.target_lun

    property target_id:
        def __get__(self):
            return self.dev.target_id

    property path_id:
        def __get__(self):
            return self.dev.path_id

    property serial:
        def __get__(self):
            return self.dev.serial_num[:self.dev.serial_num_len]


cdef class CamEnclosureElement(object):
    cdef readonly object type
    cdef readonly object description
    cdef object devnames_str

    def __getstate__(self):
        return {

        }

    property devnames:
        def __get__(self):
            return self.devnames_str.split(',')


cdef class CamEnclosure(object):
    cdef int fd

    def __init__(self, path):
        self.fd = os.open(path, os.O_RDWR)

    def __dealloc__(self):
        if self.fd >= 0:
            os.close(self.fd)

    def __getstate__(self):
        return {
            'name': self.name,
            'id': self.id,
            'status': self.status
        }

    property name:
        def __get__(self):
            cdef defs.encioc_string stri
            cdef char str[255]
            cdef int ret

            stri.bufsiz = sizeof(str)
            stri.buf = <uint8_t *>str

            with nogil:
                ret = ioctl(self.fd, defs.ENCIOC_GETENCNAME, &stri)

            if ret != 0:
                raise OSError(errno, os.strerror(errno))

            return str

    property id:
        def __get__(self):
            cdef defs.encioc_string stri
            cdef char str[255]
            cdef int ret

            stri.bufsiz = sizeof(str)
            stri.buf = <uint8_t *>str

            with nogil:
                ret = ioctl(self.fd, defs.ENCIOC_GETENCID, &stri)

            if ret != 0:
                raise OSError(errno, os.strerror(errno))

            return str

    property status:
        def __get__(self):
            pass

    property elements:
        def __get__(self):
            cdef CamEnclosureElement element
            cdef defs.encioc_elm_status e_status
            cdef defs.encioc_elm_desc e_desc
            cdef defs.encioc_elm_devnames e_devnames
            cdef defs.encioc_element *e_ptr
            cdef unsigned int nobj
            cdef char buf[1024]
            cdef int ret

            with nogil:
                ret = ioctl(self.fd, defs.ENCIOC_GETNELM, &nobj)

            if ret != 0:
                raise OSError(errno, os.strerror(errno))

            e_ptr = <defs.encioc_element *>malloc(sizeof(defs.encioc_element) * nobj)

            with nogil:
                ret = ioctl(self.fd ,defs.ENCIOC_GETELMMAP, e_ptr)

            if ret != 0:
                raise OSError(errno, os.strerror(errno))

            for i in range(0, nobj):
                element = CamEnclosureElement.__new__(CamEnclosureElement)
                memset(&e_status, 0, sizeof(e_status))
                e_status.elm_idx = e_ptr[i].elm_idx

                with nogil:
                    ret = ioctl(self.fd, defs.ENCIOC_GETELMSTAT, &nobj)

                if ret != 0:
                    pass

                element.type = EnclosureElementType(e_ptr.elm_type)

                e_desc.elm_idx = e_ptr[i].elm_idx
                e_desc.elm_desc_len = sizeof(buf)
                e_desc.elm_desc_str = buf

                with nogil:
                    ret = ioctl(self.fd, defs.ENCIOC_GETELMDESC, &e_desc)

                if ret == 0:
                    element.description = e_desc.elm_desc_str

                e_devnames.elm_idx = e_ptr[i].elm_idx
                e_devnames.elm_names_size = sizeof(buf)
                e_devnames.elm_devnames = buf

                with nogil:
                    ret = ioctl(self.fd, defs.ENCIOC_GETELMDEVNAMES, &e_devnames)

                if ret == 0:
                    element.devnames_str = e_devnames.elm_devnames

    property devices:
        def __get__(self):
            pass

    property sensors:
        def __get__(self):
            pass
