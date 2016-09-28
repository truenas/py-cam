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

from libc.stdint cimport *


cdef extern from "fcntl.h":
    enum:
        O_RDWR


cdef extern from "camlib.h" nogil:
    ctypedef int path_id_t
    ctypedef int lun_id_t
    ctypedef int target_id_t

    enum:
        MAXPATHLEN
        DEV_IDLEN
        SIM_IDLEN

    cdef struct cam_device:
        char device_path[MAXPATHLEN + 1]
        char given_dev_name[DEV_IDLEN + 1]
        uint32_t given_unit_number
        char device_name[DEV_IDLEN + 1]
        uint32_t dev_unit_num
        char sim_name[SIM_IDLEN + 1]
        uint32_t sim_unit_number
        uint32_t bus_id
        lun_id_t target_lun
        target_id_t target_id
        path_id_t path_id
        uint16_t pd_type
        uint8_t serial_num[252]
        uint8_t serial_num_len
        uint8_t sync_period
        uint8_t sync_offset
        uint8_t bus_width
        int fd

    cdef cam_device* cam_open_device(char* path, int flags)
    cdef void cam_close_device(cam_device* dev)
    cdef ccb *cam_getccb(cam_device* dev)
    cdef int cam_send_ccb(cam_device* dev, ccb* ccb)


cdef extern from "cam/cam_ccb.h":
    cdef struct ccb_hdr:
        uint32_t status
        uint32_t flags
        uint32_t xflags

    cdef struct ccb_scsiio:
        pass

    cdef union ccb:
        ccb_hdr ccb_h


cdef extern from "cam/scsi/scsi_all.h" nogil:
    ctypedef void * ccb_callback_t

    cdef struct scsi_read_capacity_data:
        uint8_t addr[4]
        uint8_t length[4]

    cdef struct scsi_report_luns_data:
        uint8_t length[4]
        uint8_t reserved[4]

    void scsi_test_unit_ready(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_request_sense(
        ccb_scsiio *csio, uint32_t retries,
        ccb_callback_t *cbfcnp,
        void *data_ptr,
        uint8_t dxfer_len,
        uint8_t tag_action,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_inquiry(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t *inq_buf,
        uint32_t inq_len,
        int evpd,
        uint8_t page_code,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_mode_sense(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int dbd,
        uint8_t page_code,
        uint8_t page,
        uint8_t *param_buf,
        uint32_t param_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_mode_sense_len(
        ccb_scsiio *csio, uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int dbd,
        uint8_t page_code,
        uint8_t page,
        uint8_t *param_buf,
        uint32_t param_len,
        int minimum_cmd_size,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_mode_select(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int scsi_page_fmt,
        int save_pages,
        uint8_t *param_buf,
        uint32_t param_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_mode_select_len(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int scsi_page_fmt,
        int save_pages,
        uint8_t *param_buf,
        uint32_t param_len,
        int minimum_cmd_size,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_log_sense(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t page_code,
        uint8_t page,
        int save_pages,
        int ppc,
        uint32_t paramptr,
        uint8_t *param_buf,
        uint32_t param_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_log_select(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t page_code,
        int save_pages,
        int pc_reset,
        uint8_t *param_buf,
        uint32_t param_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_prevent(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t action,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_read_capacity(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        scsi_read_capacity_data *,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_read_capacity_16(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint64_t lba,
        int reladr,
        int pmi,
        uint8_t *rcap_buf,
        int rcap_buf_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_report_luns(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t select_report,
        scsi_report_luns_data *rpl_buf,
        uint32_t alloc_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_report_target_group(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t pdf,
        void *buf,
        uint32_t alloc_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_set_target_group(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        void *buf,
        uint32_t alloc_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_synchronize_cache(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint32_t begin_lba,
        uint16_t lb_count,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_receive_diagnostic_results(
        ccb_scsiio *csio, uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int pcv,
        uint8_t page_code,
        uint8_t *data_ptr,
        uint16_t allocation_length,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_send_diagnostic(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int unit_offline,
        int device_offline,
        int self_test,
        int page_format,
        int self_test_code,
        uint8_t *data_ptr,
        uint16_t param_list_length,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_read_buffer(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int mode,
        uint8_t buffer_id,
        uint32_t offset,
        uint8_t *data_ptr,
        uint32_t allocation_length,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_write_buffer(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int mode,
        uint8_t buffer_id,
        uint32_t offset,
        uint8_t *data_ptr,
        uint32_t param_list_length,
        uint8_t sense_len,
        uint32_t timeout
    )

    enum:
        SCSI_RW_READ
        SCSI_RW_WRITE
        SCSI_RW_DIRMASK
        SCSI_RW_BIO

    void scsi_read_write(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int readop,
        uint8_t byte2,
        int minimum_cmd_size,
        uint64_t lba,
        uint32_t block_count,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_write_same(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t byte2,
        int minimum_cmd_size,
        uint64_t lba,
        uint32_t block_count,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_ata_identify(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t *data_ptr,
        uint16_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_ata_trim(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint16_t block_count,
        uint8_t *data_ptr,
        uint16_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_ata_pass_16(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint32_t flags,
        uint8_t tag_action,
        uint8_t protocol,
        uint8_t ata_flags,
        uint16_t features,
        uint16_t sector_count,
        uint64_t lba,
        uint8_t command,
        uint8_t control,
        uint8_t *data_ptr,
        uint16_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_unmap(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t byte2,
        uint8_t *data_ptr,
        uint16_t dxfer_len,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_start_stop(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int start,
        int load_eject,
        int immediate,
        uint8_t sense_len,
        uint32_t timeout
    )

    void scsi_read_attribute(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint8_t service_action,
        uint32_t element,
        uint8_t elem_type,
        int logical_volume,
        int partition,
        uint32_t first_attribute,
        int cache,
        uint8_t *data_ptr,
        uint32_t length,
        int sense_len,
        uint32_t timeout
    )

    void scsi_write_attribute(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint32_t element,
        int logical_volume,
        int partition,
        int wtc,
        uint8_t *data_ptr,
        uint32_t length,
        int sense_len,
        uint32_t timeout
    )

    void scsi_security_protocol_in(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint32_t security_protocol,
        uint32_t security_protocol_specific,
        int byte4,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )

    void scsi_security_protocol_out(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        uint32_t security_protocol,
        uint32_t security_protocol_specific,
        int byte4,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )

    void scsi_persistent_reserve_in(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int service_action,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )

    void scsi_persistent_reserve_out(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int service_action,
        int scope,
        int res_type,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )

    void scsi_report_supported_opcodes(
        ccb_scsiio *csio,
        uint32_t retries,
        ccb_callback_t *cbfcnp,
        uint8_t tag_action,
        int options,
        int req_opcode,
        int req_service_action,
        uint8_t *data_ptr,
        uint32_t dxfer_len,
        int sense_len,
        int timeout
    )


cdef extern from "cam/ctl/ctl.h":
    ctypedef enum ctl_port_type:
        CTL_PORT_NONE
        CTL_PORT_FC
        CTL_PORT_SCSI
        CTL_PORT_IOCTL
        CTL_PORT_INTERNAL
        CTL_PORT_ISCSI
        CTL_PORT_SAS
        CTL_PORT_ALL
        CTL_PORT_ISC

    cdef struct ctl_port_entry:
        ctl_port_type port_type
        char port_name[64]
        int32_t targ_port
        int physical_port
        int virtual_port
        unsigned int flags
        uint64_t wwnn
        uint64_t wwpn
        int online


cdef extern from "cam/ctl/ctl_io.h":
    pass


cdef extern from "cam/ctl/ctl_backend.h":
    enum:
        CTL_BE_NAME_LEN


cdef extern from "cam/ctl/ctl_ioctl.h":
    enum:
        CTL_ERROR_STR_LEN
        
    enum:
        CTL_IO
        CTL_ENABLE_PORT
        CTL_DISABLE_PORT
        CTL_DUMP_OOA
        CTL_CHECK_OOA
        CTL_HARD_STOP
        CTL_HARD_START
        CTL_DELAY_IO
        CTL_REALSYNC_GET
        CTL_REALSYNC_SET
        CTL_SETSYNC
        CTL_GETSYNC
        CTL_GETSTATS
        CTL_ERROR_INJECT
        CTL_BBRREAD
        CTL_GET_OOA
        CTL_DUMP_STRUCTS
        CTL_GET_PORT_LIST
        CTL_LUN_REQ
        CTL_LUN_LIST
        CTL_ERROR_INJECT_DELETE
        CTL_SET_PORT_WWNS
        CTL_ISCSI
        CTL_PORT_REQ
        CTL_PORT_LIST
        CTL_LUN_MAP            

    ctypedef enum ctl_iscsi_status:
        CTL_ISCSI_OK
        CTL_ISCSI_ERROR
        CTL_ISCSI_LIST_NEED_MORE_SPACE
        CTL_ISCSI_SESSION_NOT_FOUND

    ctypedef enum ctl_iscsi_type:
        CTL_ISCSI_HANDOFF
        CTL_ISCSI_LIST
        CTL_ISCSI_LOGOUT
        CTL_ISCSI_TERMINATE
        CTL_ISCSI_LISTEN
        CTL_ISCSI_ACCEPT
        CTL_ISCSI_SEND
        CTL_ISCSI_RECEIVE

    ctypedef enum ctl_lun_list_status:
        CTL_LUN_LIST_NONE
        CTL_LUN_LIST_OK
        CTL_LUN_LIST_NEED_MORE_SPACE
        CTL_LUN_LIST_ERROR

    cdef struct ctl_iscsi_list_params:
        uint32_t alloc_len
        char* conn_xml
        uint32_t fill_len
        int	spare[4]

    cdef union ctl_iscsi_data:
        ctl_iscsi_list_params list

    cdef struct ctl_iscsi:
        ctl_iscsi_type type
        ctl_iscsi_data data
        ctl_iscsi_status status
        char error_str[CTL_ERROR_STR_LEN]

    cdef struct ctl_lun_list:
        char backend[CTL_BE_NAME_LEN]
        uint32_t alloc_len
        char *lun_xml
        uint32_t fill_len
        ctl_lun_list_status status
        char error_str[CTL_ERROR_STR_LEN]


cdef extern from "cam/scsi/scsi_enc.h":
    enum:
        ENCIOC_GETNELM
        ENCIOC_GETELMMAP
        ENCIOC_GETENCSTAT
        ENCIOC_SETENCSTAT
        ENCIOC_GETELMSTAT
        ENCIOC_SETELMSTAT
        ENCIOC_GETTEXT
        ENCIOC_INIT
        ENCIOC_GETELMDESC
        ENCIOC_GETELMDEVNAMES
        ENCIOC_GETSTRING
        ENCIOC_SETSTRING
        ENCIOC_GETENCNAME
        ENCIOC_GETENCID

    ctypedef enum elm_type_t:
        ELMTYP_UNSPECIFIED
        ELMTYP_DEVICE
        ELMTYP_POWER
        ELMTYP_FAN
        ELMTYP_THERM
        ELMTYP_DOORLOCK
        ELMTYP_ALARM
        ELMTYP_ESCC
        ELMTYP_SCC
        ELMTYP_NVRAM
        ELMTYP_INV_OP_REASON
        ELMTYP_UPS
        ELMTYP_DISPLAY
        ELMTYP_KEYPAD
        ELMTYP_ENCLOSURE
        ELMTYP_SCSIXVR
        ELMTYP_LANGUAGE
        ELMTYP_COMPORT
        ELMTYP_VOM
        ELMTYP_AMMETER
        ELMTYP_SCSI_TGT
        ELMTYP_SCSI_INI
        ELMTYP_SUBENC
        ELMTYP_ARRAY_DEV
        ELMTYP_SAS_EXP
        ELMTYP_SAS_CONN

    cdef struct encioc_element:
        unsigned int elm_idx
        unsigned int elm_subenc_id
        elm_type_t elm_type

    cdef struct encioc_elm_status:
        unsigned int elm_idx
        unsigned char cstat[4]

    cdef struct encioc_elm_desc:
        unsigned int elm_idx
        uint16_t elm_desc_len
        char *elm_desc_str

    cdef struct encioc_elm_devnames:
        unsigned int elm_idx
        size_t elm_names_size
        size_t elm_names_len
        char *elm_devnames

