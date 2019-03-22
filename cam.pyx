# cython: language_level=3, c_string_type=unicode, c_string_encoding=default
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
import errno as pyerrno
import os
from posix.ioctl cimport ioctl
from libc.errno cimport errno
from libc.string cimport memset, memcpy
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


class EnclosureStatus(enum.IntEnum):
    UNRECOV = defs.SES_ENCSTAT_UNRECOV
    CRITICAL = defs.SES_ENCSTAT_CRITICAL
    NONCRITICAL = defs.SES_ENCSTAT_NONCRITICAL
    INFO = defs.SES_ENCSTAT_INFO
    INVOP = defs.SES_ENCSTAT_INVOP
    OK = 0x80000000


class ElementStatus(enum.IntEnum):
    UNSUPPORTED = defs.SES_OBJSTAT_UNSUPPORTED
    OK = defs.SES_OBJSTAT_OK
    CRIT = defs.SES_OBJSTAT_CRIT
    NONCRIT = defs.SES_OBJSTAT_NONCRIT
    UNRECOV = defs.SES_OBJSTAT_UNRECOV
    NOTINSTALLED = defs.SES_OBJSTAT_NOTINSTALLED
    UNKNOWN = defs.SES_OBJSTAT_UNKNOWN
    NOTAVAIL = defs.SES_OBJSTAT_NOTAVAIL
    NOACCESS = defs.SES_OBJSTAT_NOACCESS


cdef get_unaligned_be16(void *p):
    cdef uint16_t u;
    memcpy(&u, p, 2)
    return defs.bswap16(u)


class SCSIReadOp(enum.IntEnum):
    READ = defs.SCSI_RW_READ
    WRITE = defs.SCSI_RW_WRITE
    DIRMASK = defs.SCSI_RW_DIRMASK
    BIO = defs.SCSI_RW_BIO


class CCBFlags(enum.IntEnum):
    DIR_IN = defs.CAM_DIR_IN


cdef class CamCCB(object):
    cdef readonly CamDevice device
    cdef defs.ccb ccb

    def __init__(self, CamDevice device):
        self.device = device

    def ata_cmd(self, flags, cmd, features, data, lba, sector_count):
        cdef int c_retries = 0
        cdef uint32_t c_flags = flags
        cdef uint8_t c_tag_action = 0
        cdef uint8_t c_cmd = cmd
        cdef uint16_t c_features = features
        cdef uint64_t c_lba = lba
        cdef uint16_t c_sector_count = sector_count
        cdef uint8_t *c_data_ptr
        cdef uint16_t c_dxfer_len = len(data)
        cdef uint32_t c_timeout = 5 * 1000

        with nogil:
            c_data_ptr = <uint8_t *>malloc(c_dxfer_len)
            memset(<void *>c_data_ptr, 0, c_dxfer_len)
            self.ccb.ataio.ccb_h.func_code = defs.XPT_ATA_IO
            self.ccb.ataio.ccb_h.flags = c_flags
            self.ccb.ataio.ccb_h.retry_count = c_retries
            self.ccb.ataio.ccb_h.cbfcnp = NULL
            self.ccb.ataio.ccb_h.timeout = c_timeout
            self.ccb.ataio.data_ptr = c_data_ptr
            self.ccb.ataio.dxfer_len = c_dxfer_len
            self.ccb.ataio.ata_flags = 0

            defs.ata_28bit_cmd(
                &self.ccb.ataio,
                c_cmd,
                c_features,
                c_lba,
                c_sector_count,
            )
        self.send()
        memcpy(<uint8_t *>data, c_data_ptr, c_dxfer_len)
        free(c_data_ptr)

    def scsi_test_unit_ready(self, **kwargs):
        pass

    def scsi_request_sense(self, **kwargs):
        cdef uint32_t c_timeout = kwargs.pop('timeout', 60 * 1000)
        cdef void *c_data

        result = kwargs.pop('data')

    def scsi_inquiry(self, **kwargs):
        pass

    def scsi_mode_sense(self, **kwargs):
        pass

    def scsi_log_sense(self, retries=0, page=0, save_pages=False, ppc=0):
        cdef uint32_t c_retries = retries
        cdef uint8_t c_page = page
        cdef int c_save_pages = save_pages
        cdef int c_ppc = ppc

        cdef uint32_t c_param_ptr
        cdef uint8_t c_param_buf[1024]
        cdef uint32_t c_param_len = 1024

        c_param_ptr = <uint32_t>&c_param_buf

        with nogil:
            defs.scsi_log_sense(
                &self.ccb.csio,
                c_retries,
                NULL,
                defs.MSG_SIMPLE_Q_TAG,
                c_page,
                0,
                c_save_pages,
                c_ppc,
                0,
                c_param_buf,
                4,
                defs.SSD_FULL_SIZE,
                60 * 1000,
            )

    def scsi_read_write(self, **kwargs):
        cdef uint32_t c_retries = kwargs.pop('retries', 0)
        cdef int c_read_op = int(kwargs.pop('read_op'))
        cdef uint64_t c_lba = kwargs.pop('lba')
        cdef uint32_t c_block_count = kwargs.pop('block_count')
        cdef uint32_t c_block_len = kwargs.pop('block_len')
        cdef int c_minimum_cmd_size = kwargs.pop('minimum_cmd_size', 0)
        cdef uint32_t c_timeout = kwargs.pop('timeout', 60 * 1000)
        cdef uint32_t c_dxfer_len = c_block_len * c_block_count
        cdef uint8_t *c_data

        result = kwargs.pop('data')
        c_data = <uint8_t *>result

        with nogil:
            defs.scsi_read_write(
                &self.ccb.csio,
                c_retries,
                NULL,
                defs.MSG_SIMPLE_Q_TAG,
                c_read_op,
                0,
                c_minimum_cmd_size,
                c_lba,
                c_block_count,
                c_data,
                c_dxfer_len,
                defs.SSD_FULL_SIZE,
                c_timeout
            )

    def scsi_start_stop(self, **kwargs):
        cdef uint32_t c_retries = kwargs.pop('retries', 0)
        cdef uint32_t c_timeout = kwargs.pop('timeout', 60 * 1000)
        cdef int c_start = kwargs.pop('start')
        cdef int c_load_eject = kwargs.pop('load_eject')
        cdef int c_immediate = kwargs.pop('immediate', False)

        with nogil:
            defs.scsi_start_stop(
                &self.ccb.csio,
                c_retries,
                NULL,
                defs.MSG_ORDERED_Q_TAG,
                c_start,
                c_load_eject,
                c_immediate,
                defs.SSD_FULL_SIZE,
                c_timeout
            )

    def scsi_synchronize_cache(self, **kwargs):
        cdef uint32_t c_retries = kwargs.pop('retries', 0)
        cdef uint32_t c_timeout = kwargs.pop('timeout', 60 * 1000)
        cdef uint64_t c_lba = kwargs.pop('lba')
        cdef uint32_t c_block_count = kwargs.pop('block_count')

        with nogil:
            defs.scsi_synchronize_cache(
                &self.ccb.csio,
                c_retries,
                NULL,
                defs.MSG_SIMPLE_Q_TAG,
                c_lba,
                c_block_count,
                defs.SSD_FULL_SIZE,
                c_timeout
            )

    def scsi_persistent_reserve_in(self, **kwargs):
        cdef uint32_t c_retries = kwargs.pop('retries', 0)
        cdef uint32_t c_timeout = kwargs.pop('timeout', 60 * 1000)
        cdef int c_service_action = kwargs.pop('service_action')
        cdef uint8_t *c_data
        cdef uint32_t c_dxfer_len

        result = kwargs.pop('data')
        c_data = <uint8_t *>result
        c_dxfer_len = len(result)

        with nogil:
            defs.scsi_persistent_reserve_in(
                &self.ccb.csio,
                c_retries,
                NULL,
                defs.MSG_SIMPLE_Q_TAG,
                c_service_action,
                c_data,
                c_dxfer_len,
                defs.SSD_FULL_SIZE,
                c_timeout
            )

    def scsi_persistent_reserve_out(self, **kwargs):
        pass

    #def scsi_format_unit(self, )

    def send(self):
        cdef int ret
        cdef char errmsg[1024]

        self.ccb.ccb_h.flags |= defs.CAM_PASS_ERR_RECOVER

        with nogil:
            ret = defs.cam_send_ccb(self.device.dev, &self.ccb)

        if ret == -1:
            raise OSError(errno, os.strerror(errno))

        status = self.ccb.ccb_h.status & defs.CAM_STATUS_MASK
        if status != defs.CAM_REQ_CMP:
            <int>defs.cam_error_string(self.device.dev, &self.ccb, <char *>&errmsg, 1024, defs.CAM_ESF_ALL, defs.CAM_EPF_ALL)
            raise OSError(pyerrno.EBADMSG, errmsg.strip())

    property resid:
        def __get__(self):
            return self.ccb.csio.resid

    property scsi_status:
        def __get__(self):
            return self.ccb.csio.scsi_status


cdef class CamDevice(object):
    cdef defs.cam_device* dev

    def __init__(self, path):
        cdef const char *c_path = path

        with nogil:
            self.dev = defs.cam_open_device(c_path, defs.O_RDWR)

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

    def read_keys(self):
        cdef defs.scsi_per_res_in_keys *pdu
        cdef uint32_t *generation
        buffer = bytearray(defs.SPRI_MAX_LEN)

        ccb = CamCCB(self)
        ccb.scsi_persistent_reserve_in(service_action=defs.SPRI_RK, data=buffer)
        ccb.send()

        print('resid = {0}'.format(ccb.resid))
        print('data = {0}'.format(buffer))

        pdu = <defs.scsi_per_res_in_keys *><void *>buffer
        generation = <uint32_t *>&pdu.header.generation[0]

        return {
            'generation': generation[0],
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
    cdef readonly CamEnclosure parent
    cdef readonly object type
    cdef readonly object description
    cdef readonly int index
    cdef unsigned char cstat[4]
    cdef object devnames_str

    def __str__(self):
        return "<cam.CamEnclosureElement type='{0}' status='{1}'>".format(self.type.name, self.status.name)

    def __repr__(self):
        return str(self)

    def __getstate__(self):
        return {
            'index': self.index,
            'type': self.type.name,
            'description': self.description,
            'status': self.status.name
        }

    property status:
        def __get__(self):
            try:
                return ElementStatus(self.cstat[0])
            except ValueError:
                return ElementStatus.UNKNOWN


cdef class CamEnclosureDevice(CamEnclosureElement):
    def __getstate__(self):
        base = super(CamEnclosureDevice, self).__getstate__()
        base['devnames'] = self.devnames
        return base

    def __str__(self):
        return "<cam.CamEnclosureDevice devnames='{0}'>".format(self.devnames)

    def identify(self, onoff, setfault):
        cdef defs.encioc_elm_status e_status
        cdef int ret

        e_status.elm_idx = self.index
        with nogil:
            ret = ioctl(self.parent.fd, defs.ENCIOC_GETELMSTAT, &e_status)

        if ret != 0:
            raise OSError(errno, os.strerror(errno))

        e_status.cstat[0] |= 0x80
        if onoff:
            e_status.cstat[2] |= 0x20 if setfault else 0x02
        else:
            e_status.cstat[2] &= 0xdf if setfault else 0xfd

        with nogil:
            ret = ioctl(self.parent.fd, defs.ENCIOC_SETELMSTAT, &e_status)

        if ret != 0:
            raise OSError(errno, os.strerror(errno))

    property devnames:
        def __get__(self):
            if not self.devnames_str:
                return None

            return self.devnames_str.split(',')


cdef class CamEnclosureFan(CamEnclosureElement):
    def __getstate__(self):
        base = super(CamEnclosureFan, self).__getstate__()
        base['speed'] = self.speed
        return base

    def __str__(self):
        return "<cam.CamEnclosureFan speed={0}>".format(self.speed)

    property speed:
        def __get__(self):
            return (((self.cstat[1] & 0x7) << 8) + self.cstat[2]) * 10


cdef class CamEnclosureThermalSensor(CamEnclosureElement):
    def __getstate__(self):
        base = super(CamEnclosureThermalSensor, self).__getstate__()
        base['temperature'] = self.temperature
        return base

    def __str__(self):
        return "<cam.CamEnclosureFan temperature={0}>".format(self.temperature)

    property temperature:
        def __get__(self):
            return self.cstat[2] - 20


cdef class CamEnclosureVoltageSensor(CamEnclosureElement):
    def __getstate__(self):
        base = super(CamEnclosureVoltageSensor, self).__getstate__()
        base['voltage'] = self.voltage
        return base

    def __str__(self):
        return "<cam.CamEnclosureFan voltage={0}>".format(self.voltage)

    property voltage:
        def __get__(self):
            return ((self.cstat[2] << 8) | self.cstat[3]) / 100


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
            'status': [i.name for i in self.status],
            'devices': [i.__getstate__() for i in self.devices]
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
            cdef unsigned char estat

            with nogil:
                ret = ioctl(self.fd, defs.ENCIOC_GETENCSTAT, &estat)

            if ret != 0:
                raise OSError(errno, os.strerror(errno))

            if estat == 0:
                return {EnclosureStatus.OK}

            return bitmask_to_set(estat, EnclosureStatus)

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
                if e_ptr[i].elm_type in (defs.ELMTYP_DEVICE, defs.ELMTYP_ARRAY_DEV):
                    cls = CamEnclosureDevice

                elif e_ptr[i].elm_type == defs.ELMTYP_FAN:
                    cls = CamEnclosureFan

                elif e_ptr[i].elm_type == defs.ELMTYP_THERM:
                    cls = CamEnclosureThermalSensor

                elif e_ptr[i].elm_type == defs.ELMTYP_VOM:
                    cls = CamEnclosureVoltageSensor

                else:
                    cls = CamEnclosureElement

                element = cls.__new__(cls)
                memset(&e_status, 0, sizeof(e_status))
                e_status.elm_idx = e_ptr[i].elm_idx
                element.parent = self
                element.index = e_ptr[i].elm_idx
                element.type = EnclosureElementType.UNSPECIFIED

                try:
                    element.type = EnclosureElementType(e_ptr[i].elm_type)
                except ValueError:
                    pass

                with nogil:
                    ret = ioctl(self.fd, defs.ENCIOC_GETELMSTAT, &e_status)

                if ret == 0:
                    memcpy(element.cstat, e_status.cstat, 4)

                memset(buf, 0, sizeof(buf))
                e_desc.elm_idx = e_ptr[i].elm_idx
                e_desc.elm_desc_len = sizeof(buf)
                e_desc.elm_desc_str = buf

                with nogil:
                    ret = ioctl(self.fd, defs.ENCIOC_GETELMDESC, &e_desc)

                if ret == 0:
                    element.description = (<bytes>e_desc.elm_desc_str).decode('ascii', 'ignore')

                memset(buf, 0, sizeof(buf))
                e_devnames.elm_idx = e_ptr[i].elm_idx
                e_devnames.elm_names_size = sizeof(buf)
                e_devnames.elm_devnames = buf

                with nogil:
                    ret = ioctl(self.fd, defs.ENCIOC_GETELMDEVNAMES, &e_devnames)

                if ret == 0:
                    element.devnames_str = e_devnames.elm_devnames

                yield element

    property devices:
        def __get__(self):
            return (i for i in self.elements if i.type in (
                EnclosureElementType.DEVICE,
                EnclosureElementType.ARRAY_DEV
            ))

    property sensors:
        def __get__(self):
            return (i for i in self.elements if i.type in (
                EnclosureElementType.THERM,
                EnclosureElementType.FAN,
                EnclosureElementType.VOM
            ))


def bitmask_to_set(n, enumeration):
    result = set()
    while n:
        b = n & (~n+1)
        try:
            result.add(enumeration(b))
        except ValueError:
            pass

        n ^= b

    return result
