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

import enum
import os
import cython
from xml.etree import ElementTree as etree
from posix.ioctl cimport ioctl
from libc.errno cimport errno
from libc.string cimport memset, strerror
from libc.stdlib cimport malloc, free
cimport defs


class CTLError(RuntimeError):
    pass


cdef class ISCSIConnection(object):
    cdef CTL parent
    cdef object xml

    def __getstate__(self):
        return {
            'initiator': self.initiator,
            'initiator_address': self.initiator_address,
            'initiator_alias': self.initiator_alias,
            'target': self.target,
            'target_alias': self.target_alias,
            'target_portal_group_tag': self.target_portal_group_tag,
            'header_digest': self.header_digest,
            'data_digest': self.data_digest,
            'max_data_segment_length': self.max_data_segment_length,
            'immediate_data': self.immediate_data,
            'iser': self.iser
        }

    def logout(self):
        pass

    def terminate(self):
        pass

    property initiator:
        def __get__(self):
            return self.xml.find('initiator').text

    property initiator_address:
        def __get__(self):
            return self.xml.find('initiator_addr').text

    property initiator_alias:
        def __get__(self):
            return self.xml.find('initiator_alias').text

    property target:
        def __get__(self):
            return self.xml.find('target').text

    property target_alias:
        def __get__(self):
            return self.xml.find('target_alias').text

    property target_portal_group_tag:
        def __get__(self):
            return self.xml.find('target_portal_group_tag').text

    property header_digest:
        def __get__(self):
            return self.xml.find('header_digest').text

    property data_digest:
        def __get__(self):
            return self.xml.find('data_digest').text

    property max_data_segment_length:
        def __get__(self):
            return int(self.xml.find('max_data_segment_length').text)

    property immediate_data:
        def __get__(self):
            return self.xml.find('immediate_data').text

    property iser:
        def __get__(self):
            return int(self.xml.find('iser').text)


class CTLPortType(enum.IntEnum):
    NONE = defs.CTL_PORT_NONE
    FC = defs.CTL_PORT_FC
    SCSI = defs.CTL_PORT_SCSI
    IOCTL = defs.CTL_PORT_IOCTL
    INTERNAL = defs.CTL_PORT_INTERNAL
    ISCSI = defs.CTL_PORT_ISCSI
    SAS = defs.CTL_PORT_SAS
    ALL = defs.CTL_PORT_ALL
    ISC = defs.CTL_PORT_ISC



cdef class CTLPort(object):
    cdef CTL parent
    cdef object xml

    def __getstate__(self):
        return {
            'id': self.id,
            'name': self.name,
            'frontend_type': self.frontend_type,
            'online': self.online,
            'physical_port': self.physical_port,
            'virtual_port': self.virtual_port,
            'target': self.target,
            'luns': self.luns,
            'initiators': self.initiators
        }

    property id:
        def __get__(self):
            return int(self.xml.attrib['id'])

    property name:
        def __get__(self):
            return self.xml.find('port_name').text

    property frontend_type:
        def __get__(self):
            return self.xml.find('frontend_type').text

    property online:
        def __get__(self):
            return self.xml.find('online').text == 'YES'

    property physical_port:
        def __get__(self):
            return int(self.xml.find('physical_port').text)

    property virtual_port:
        def __get__(self):
            return int(self.xml.find('virtual_port').text)

    property target:
        def __get__(self):
            node = self.xml.find('target')
            return node.text if node else None

    property luns:
        def __get__(self):
            result = {}
            for i in self.xml.findall('lun'):
                result[i.attrib['id']] = int(i.text)

            return result


    property initiators:
        def __get__(self):
            result = {}
            for i in self.xml.findall('initiator'):
                result[i.attrib['id']] = i.text

            return result


cdef class CTL(object):
    cdef int fd

    def __init__(self, path='/dev/cam/ctl'):
        self.fd = os.open(path, os.O_RDWR)

    def __dealloc__(self):
        if self.fd:
            os.close(self.fd)

    property iscsi_connections:
        def __get__(self):
            cdef ISCSIConnection conn
            cdef defs.ctl_iscsi req
            cdef char* buffer
            cdef int size = 4096
            cdef int ret

            while True:
                buffer = <char*>malloc(size)
                memset(&req, 0, cython.sizeof(req))
                req.type = defs.CTL_ISCSI_LIST
                req.data.list.alloc_len = size
                req.data.list.conn_xml = buffer

                with nogil:
                    ret = ioctl(self.fd, defs.CTL_ISCSI, <void*>&req)

                if ret != 0:
                    raise OSError(errno, strerror(errno))

                if req.status == defs.CTL_ISCSI_LIST_NEED_MORE_SPACE:
                    size <<= 1
                    free(buffer)
                    continue

                break

            if req.status != defs.CTL_ISCSI_OK:
                raise CTLError(req.error_str)

            xml = etree.fromstring(buffer)
            for i in xml.findall('connection'):
                conn = ISCSIConnection.__new__(ISCSIConnection)
                conn.parent = self
                conn.xml = i
                yield conn

    property ports:
        def __get__(self):
            cdef CTLPort port
            cdef defs.ctl_lun_list req
            cdef char* buffer
            cdef int size = 4096
            cdef int ret

            while True:
                buffer = <char*>malloc(size)
                memset(&req, 0, cython.sizeof(req))
                req.status = defs.CTL_LUN_LIST_NONE
                req.alloc_len = size
                req.lun_xml = buffer

                with nogil:
                    ret = ioctl(self.fd, defs.CTL_PORT_LIST, <void*>&req)

                if ret != 0:
                    raise OSError(errno, strerror(errno))

                if req.status == defs.CTL_LUN_LIST_NEED_MORE_SPACE:
                    size <<= 1
                    free(buffer)
                    continue

                break

            if req.status != defs.CTL_LUN_LIST_OK:
                raise CTLError(req.error_str)

            xml = etree.fromstring(buffer)
            for i in xml.findall('targ_port'):
                port = CTLPort.__new__(CTLPort)
                port.parent = self
                port.xml = i
                yield port
