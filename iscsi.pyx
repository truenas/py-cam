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
from posix.ioctl cimport ioctl
from libc.errno cimport errno


cdef class ISCSISessionConfig(object):
    cdef readonly ISCSIInitiator parent
    cdef defs.iscsi_session_conf *conf

    property initiator:
        def __get__(self):
            pass

    property initiator_address:
        def __get__(self):
            pass

    property initiator_alias:
        def __get__(self):
            pass

    property target:
        def __get__(self):
            pass

    property target_address:
        def __get__(self):
            pass

    property user:
        def __get__(self):
            pass

    property secret:
        def __get__(self):
            pass

    property mutual_user:
        def __get__(self):
            pass

    property mutual_secret:
        def __get__(self):
            pass

    property discovery:
        def __get__(self):
            pass


cdef class ISCSISessionState(object):
    cdef readonly ISCSIInitiator parent
    cdef defs.iscsi_session_state *state

    property id:
        def __get__(self):
            pass

    property alias:
        def __get__(self):
            pass

    property connected:
        def __get__(self):
            pass


cdef class ISCSIInitiator(object):
    cdef int fd

    def __init__(self):
        self.fd = os.open("/dev/iscsi", os.O_RDWR)

    def add_session(self, session):
        pass

    def remove_session(self, session_or_id):
        pass

    property sessions:
        def __get__(self):
            pass
