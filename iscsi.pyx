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
import os
from libc.errno cimport errno
from posix.ioctl cimport ioctl
from libc.string cimport memset, memcpy
from libc.stdlib cimport realloc, free


cdef extern from "errno.h":
    enum:
        EMSGSIZE


cdef extern from "string.h":
    size_t strlcpy(char *dst, const char *src, size_t dstsize)


cdef class ISCSISessionConfig(object):
    cdef readonly ISCSIInitiator parent
    cdef defs.iscsi_session_conf conf

    def __init__(self):
        memset(&self.conf, 0, sizeof(defs.iscsi_session_conf))
        self.conf.isc_header_digest = 1
        self.conf.isc_data_digest = 1


    property initiator:
        def __get__(self):
            return self.conf.isc_initiator

        def __set__(self, value):
            strlcpy(self.conf.isc_initiator, value, defs.ISCSI_NAME_LEN)

    property initiator_address:
        def __get__(self):
            return self.conf.isc_initiator_addr

        def __set__(self, value):
            strlcpy(self.conf.isc_initiator_addr, value, defs.ISCSI_ADDR_LEN)

    property initiator_alias:
        def __get__(self):
            return self.conf.isc_initiator_alias

        def __set__(self, value):
            strlcpy(self.conf.isc_initiator_alias, value, defs.ISCSI_ALIAS_LEN)

    property target:
        def __get__(self):
            return self.conf.isc_target

        def __set__(self, value):
            strlcpy(self.conf.isc_target, value, defs.ISCSI_NAME_LEN)

    property target_address:
        def __get__(self):
            return self.conf.isc_target_addr

        def __set__(self, value):
            strlcpy(self.conf.isc_target_addr, value, defs.ISCSI_ADDR_LEN)

    property user:
        def __get__(self):
            return self.conf.isc_user

        def __set__(self, value):
            strlcpy(self.conf.isc_user, value or '', defs.ISCSI_NAME_LEN)

    property secret:
        def __get__(self):
            return self.conf.isc_secret

        def __set__(self, value):
            strlcpy(self.conf.isc_secret, value or '', defs.ISCSI_SECRET_LEN)

    property mutual_user:
        def __get__(self):
            return self.conf.isc_mutual_user

        def __set__(self, value):
            strlcpy(self.conf.isc_mutual_user, value or '', defs.ISCSI_NAME_LEN)

    property mutual_secret:
        def __get__(self):
            return self.conf.isc_mutual_secret

        def __set__(self, value):
            strlcpy(self.conf.isc_mutual_secret, value or '', defs.ISCSI_SECRET_LEN)

    property discovery:
        def __get__(self):
            return self.conf.isc_discovery

        def __set__(self, value):
            self.conf.isc_discovery = bool(value)

    property enable:
        def __get__(self):
            return self.conf.isc_enable

        def __set__(self, value):
            self.conf.isc_enable = bool(value)



cdef class ISCSISessionState(object):
    cdef readonly ISCSIInitiator parent
    cdef defs.iscsi_session_state state

    property id:
        def __get__(self):
            return self.state.iss_id

    property alias:
        def __get__(self):
            return self.state.iss_target_alias

    property reason:
        def __get__(self):
            return self.state.iss_reason

    property connected:
        def __get__(self):
            return bool(self.state.iss_connected)

    property config:
        def __get__(self):
            cdef ISCSISessionConfig cfg

            cfg = ISCSISessionConfig.__new__(ISCSISessionConfig)
            memcpy(&cfg.conf, &self.state.iss_conf, sizeof(defs.iscsi_session_conf))
            return cfg


cdef class ISCSIInitiator(object):
    cdef int fd

    def __init__(self):
        self.fd = os.open("/dev/iscsi", os.O_RDWR)

    def __dealloc__(self):
        try:
            os.close(self.fd)
        except:
            pass

    def add_session(self, ISCSISessionConfig session):
        cdef defs.iscsi_session_add isa
        cdef int ret

        memset(&isa, 0, sizeof(isa))
        memcpy(&isa.isa_conf, &session.conf, sizeof(defs.iscsi_session_conf))

        with nogil:
            err = ioctl(self.fd, defs.ISCSISADD, <void *>&isa)

        if err != 0:
            raise OSError(errno, os.strerror(errno))

    def remove_session(self, session_or_id):
        cdef defs.iscsi_session_remove isr
        cdef int err

        if isinstance(session_or_id, ISCSISessionState):
            id = session_or_id.id
        else:
            id = session_or_id

        memset(&isr, 0, sizeof(isr))
        isr.isr_session_id = id

        with nogil:
            err = ioctl(self.fd, defs.ISCSISREMOVE, <void *>&isr)

        if err != 0:
            raise OSError(errno, os.strerror(errno))

    def modify_session(self, session_or_id, ISCSISessionConfig config):
        cdef defs.iscsi_session_modify ism
        cdef int err

        if isinstance(session_or_id, ISCSISessionState):
            id = session_or_id.id
        else:
            id = session_or_id

        memset(&ism, 0, sizeof(ism))
        ism.ism_session_id = id
        memcpy(&ism.ism_conf, &config.conf, sizeof(defs.iscsi_session_conf))

        with nogil:
            err = ioctl(self.fd, defs.ISCSISREMOVE, <void *>&ism)

        if err != 0:
            raise OSError(errno, os.strerror(errno))

    property sessions:
        def __get__(self):
            cdef ISCSISessionState ses
            cdef defs.iscsi_session_state *states = <defs.iscsi_session_state *>NULL
            cdef defs.iscsi_session_list isl
            cdef int nentries = 5
            cdef int err

            while True:
                states = <defs.iscsi_session_state *>realloc(states, nentries * sizeof(defs.iscsi_session_state))

                memset(&isl, 0, sizeof(isl))
                isl.isl_nentries = nentries
                isl.isl_pstates = states
                with nogil:
                    err = ioctl(self.fd, defs.ISCSISLIST, <void *>&isl)

                if err != 0 and errno == EMSGSIZE:
                    nentries *= 2
                    continue

                break

            if err != 0:
                free(states)
                raise OSError(errno, os.strerror(errno))

            try:
                for i in range(0, isl.isl_nentries):
                    ses = ISCSISessionState.__new__(ISCSISessionState)
                    memcpy(&ses.state, &states[i], sizeof(defs.iscsi_session_state))
                    yield ses
            finally:
                free(states)
