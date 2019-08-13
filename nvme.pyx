# cython: language_level=3, c_string_type=unicode, c_string_encoding=default
#-
# Copyright (c) 2019 iXsystems, Inc.
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

from libc cimport errno
from libc.stdint cimport uint32_t
import os
from posix.ioctl cimport ioctl


cdef extern from "dev/nvme/nvme.h":
    int NVME_GET_NSID

    struct nvme_get_nsid:
        char cdev[256]
        uint32_t nsid


def get_nsid(path):
    cdef nvme_get_nsid nsid
    cdef int fd = os.open(path, os.O_RDONLY)
    if fd == -1:
        raise OSError(errno.errno, os.strerror(errno.errno), path)
    try:
        with nogil:
            res = ioctl(fd, NVME_GET_NSID, &nsid)
        if res == -1:
            raise OSError(errno.errno, os.strerror(errno.errno), path)

        return nsid.cdev
    finally:
        os.close(fd)
