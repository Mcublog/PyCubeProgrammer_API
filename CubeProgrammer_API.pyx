"""
Define thin Python wrapper for CubeProgrammer_API using Cython.
This generates a .PYD python extension.
Members added to read and write symbols e.g., floats etc.
"""

import struct

cdef extern from "stddef.h":
    ctypedef void wchar_t

from cpython.ref cimport PyObject
cdef extern from "Python.h":
    PyObject* PyUnicode_FromWideChar(wchar_t *w, Py_ssize_t size)
    wchar_t* PyUnicode_AsWideCharString(object, Py_ssize_t*) except NULL


# Tell Cython what C constructs we wish to use from this C header file
cdef extern from "./api/include/CubeProgrammer_API.h":

    cdef enum cubeProgrammerError:
        CUBEPROGRAMMER_NO_ERROR = 0, # Success (no error)
        CUBEPROGRAMMER_ERROR_NOT_CONNECTED = -1, # Device not connected
        CUBEPROGRAMMER_ERROR_NO_DEVICE = -2, # Device not found
        CUBEPROGRAMMER_ERROR_CONNECTION = -3, # Device connection error
        CUBEPROGRAMMER_ERROR_NO_FILE = -4, # No such file
        CUBEPROGRAMMER_ERROR_NOT_SUPPORTED = -5, # Operation not supported or unimplemented on this interface
        CUBEPROGRAMMER_ERROR_INTERFACE_NOT_SUPPORTED = -6, # Interface not supported or unimplemented on this plateform
        CUBEPROGRAMMER_ERROR_NO_MEM = -7, # Insufficient memory
        CUBEPROGRAMMER_ERROR_WRONG_PARAM = -8, # Wrong parameters
        CUBEPROGRAMMER_ERROR_READ_MEM = -9, # Memory read failure
        CUBEPROGRAMMER_ERROR_WRITE_MEM = -10, # Memory write failure
        CUBEPROGRAMMER_ERROR_ERASE_MEM = -11, # Memory erase failure
        CUBEPROGRAMMER_ERROR_UNSUPPORTED_FILE_FORMAT = -12, # File format not supported for this kind of device
        CUBEPROGRAMMER_ERROR_REFRESH_REQUIRED = -13, # Refresh required
        CUBEPROGRAMMER_ERROR_NO_SECURITY = -14, # Refresh required
        CUBEPROGRAMMER_ERROR_CHANGE_FREQ = -15, # Changing frequency problem
        CUBEPROGRAMMER_ERROR_RDP_ENABLED = -16, # RDP Enabled error
        CUBEPROGRAMMER_ERROR_OTHER = -99, # Other error

    cdef enum debugConnectMode:
        NORMAL_MODE = 0,        # Connect with normal mode, the target is reset then halted while the type of reset is selected using the [debugResetMode].
        HOTPLUG_MODE,           # Connect with hotplug mode,  this option allows the user to connect to the target without halt or reset.
        UNDER_RESET_MODE,       # Connect with under reset mode, option allows the user to connect to the target using a reset vector catch before executing any instruction.
        POWER_DOWN_MODE,        # Connect with power down mode.
        PRE_RESET_MODE          # Connect with pre reset mode.

    cdef enum debugPort:
        JTAG = 0,
        SWD = 1,

    cdef enum debugResetMode:
        SOFTWARE_RESET,         # Apply a reset by the software.
        HARDWARE_RESET,         # Apply a reset by the hardware.
        CORE_RESET              # Apply a reset by the internal core peripheral.

    cdef struct frequencies:
        unsigned int jtagFreq[12]           #  JTAG frequency.
        unsigned int jtagFreqNumber         #  Get JTAG supported frequencies.
        unsigned int swdFreq[12]            #  SWD frequency.
        unsigned int swdFreqNumber          #  Get SWD supported frequencies.

    # https://cython.readthedocs.io/en/latest/src/userguide/external_C_code.html#styles-of-struct-union-and-enum-declaration
    cdef struct debugConnectParameters:
        debugPort dbgPort                  # Select the type of debug interface #debugPort.
        int index                          # Select one of the debug ports connected.
        char serialNumber[33]              # ST-LINK serial number.
        char firmwareVersion[20]           # Firmware version.
        char targetVoltage[5]              # Operate voltage.
        int accessPortNumber               # Number of available access port.
        int accessPort                     # Select access port controller.
        debugConnectMode connectionMode    # Select the debug CONNECT mode #debugConnectMode.
        debugResetMode resetMode           # Select the debug RESET mode #debugResetMode.
        int isOldFirmware                  # Check Old ST-LINK firmware version.
        frequencies freq                   # Supported frequencies #frequencies.
        int frequency                      # Select specific frequency.
        int isBridge                       # Indicates if it's Bridge device or not.
        int shared                         # Select connection type, if it's shared, use ST-LINK Server.
        char board[100]                    # board Name
        int DBG_Sleep

    cdef struct dfuConnectParameters:
        char *usb_index
        char rdu                       # **< request a read unprotect: value in {0,1}.

    cdef struct dfuDeviceInfo:
        char usbIndex[10]                  # USB index.
        int busNumber                      # Bus number.
        int addressNumber                  # Address number.
        char productId[100]                # Product number.
        char serialNumber[100]             # Serial number.
        unsigned int dfuVersion            # DFU version.

    cdef struct bitCoefficient_C:
        unsigned int multiplier         # Bit multiplier. */
        unsigned int offset             # Bit offset. */

    cdef struct bitValue_C:
        unsigned int value              # Option bit value. */
        char description[200]           # Option bit description. */

    cdef struct bit_C:
        char name[32]                   # Bit name such as RDP, BOR_LEV, nBOOT0... */
        char description[300]           # Config description. */
        unsigned int wordOffset        # Word offset. */
        unsigned int bitOffset         # Bit offset. */
        unsigned int bitWidth          # Number of bits build the option. */
        unsigned char access            # Access Read/Write. */
        unsigned int valuesNbr         # Number of possible values. */
        bitValue_C** values             # Bits value, #BitValue_C. */
        bitCoefficient_C equation       # Bits equation, #BitCoefficient_C. */
        unsigned char* reference
        unsigned int bitValue

    cdef struct category_C:
        char name[100]                  # Get category name such as Read Out Protection, BOR Level... */
        unsigned int bitsNbr           # Get bits number of the considered category. */
        bit_C** bits                    # Get internal bits descriptions. */

    cdef struct bank_C:
        unsigned int size               # Bank size. */
        unsigned int address            # Bank starting address. */
        unsigned char access            # Bank access Read/Write. */
        unsigned int categoriesNbr     # Number of option bytes categories. */
        category_C** categories         # Get bank categories descriptions #Category_C. */

    cdef struct peripheral_C:
        char name[32]                 # Peripheral name.
        char description[200]         # Peripheral description.
        unsigned int banksNbr         # Number of existed banks.
        bank_C** banks                # Get banks descriptions #Bank_C.


    # define C typedefs for 3 callback functions.
    ctypedef void (*PCCbInitProgressBar)()
    ctypedef void (*PCCbLogMessage)(int msgType,  const wchar_t* str)
    ctypedef void (*PCCbLoadBar)(int x, int n)

    cdef struct displayCallBacks:
        PCCbInitProgressBar initProgressBar                          # Add a progress bar.
        PCCbLogMessage      logMessage                               # Display internal messages according to verbosity level.
        PCCbLoadBar         loadBar                                  # Display the loading of read/write process.

    cdef struct generalInf:
        unsigned short deviceId   # Device ID.
        int  flashSize            # Flash memory size.
        int  bootloaderVersion    # Bootloader version
        char type[4]              # Device MCU or MPU.
        char cpu[20]              # Cortex CPU.
        char name[100]            # Device name.
        char series[100]          # Device serie.
        char description[150]     # Take notice.
        char revisionId[100]      # Revision ID.
        char board[100]           # Board Rpn.

    int api_checkDeviceConnection "checkDeviceConnection" ()
    int api_getStLinkList "getStLinkList" (debugConnectParameters** stLinkList, int shared)
    int api_connectStLink "connectStLink" (debugConnectParameters debugParameters)
    int api_getDfuDeviceList "getDfuDeviceList" (dfuDeviceInfo** dfuList, int iPID, int iVID)
    int api_connectDfuBootloader2 "connectDfuBootloader2" (dfuConnectParameters dfuParameters)
    int api_readMemory "readMemory" (unsigned int address, unsigned char** data, unsigned int byte_qty)
    int api_writeMemory "writeMemory" (unsigned int address, char* data, unsigned int byte_qty)
    void api_disconnect "disconnect" ()
    int api_readUnprotect "readUnprotect" ()
    generalInf * api_getDeviceGeneralInf "getDeviceGeneralInf" ()
    int api_downloadFile "downloadFile" (const wchar_t* filePath, unsigned int address, unsigned int skipErase, unsigned int verify, const wchar_t* binPath)
    int api_execute "execute" (unsigned int address)
    int api_reset "reset" (debugResetMode rstMode)

    void api_setDisplayCallbacks "setDisplayCallbacks" (displayCallBacks c)
    void api_setLoadersPath "setLoadersPath" (const char* path)

    int api_sendOptionBytesCmd "sendOptionBytesCmd" (char* command)
    peripheral_C* api_initOptionBytesInterface "initOptionBytesInterface" ()
    int api_obDisplay "obDisplay" ()


cdef class CubeProgrammer_API:
    cdef int c_stlink_connected
    cdef int c_device_connected
    cdef int c_dfu_connected
    py_stlink_list: []
    py_dfu_list: []

    @property
    def stlink_list(self):
        return self.py_stlink_list

    @property
    def stlink_connected(self):
        return self.c_stlink_connected != 0

    @property
    def dfu_list(self):
        return self.py_dfu_list

    @property
    def dfu_connected(self):
        return self.c_dfu_connected != 0

    @property
    def device_connected(self):
        return self.c_device_connected != 0

    def __init__(self):
        cdef const char* path = "./"
        api_setLoadersPath(path)

        global display_cb_struct
        api_setDisplayCallbacks(display_cb_struct)

        self.c_stlink_connected = False
        self.c_device_connected = False
        self.py_stlink_list = None

        self.c_dfu_connected = False
        self.py_dfu_list = None

    def setDisplayCallbacks(self, initProgressBar, logMessage, loadBar):
        global py_cb_InitProgressBar, py_cb_LogMessage, py_cb_LoadBar

        py_cb_InitProgressBar = initProgressBar
        py_cb_LogMessage = logMessage
        py_cb_LoadBar = loadBar

    def setLoadersPath(self, path):
        str = f'setLoadersPath({path})'
        c_cb_LogMessage(4, PyUnicode_AsWideCharString(str, NULL))
        cdef bytes x = path.encode()
        api_setLoadersPath(x)

    def checkDeviceConnection(self):
        return api_checkDeviceConnection()

    def getStLinkList(self):
        global stLinkList
        stLinkListLen = api_getStLinkList(&stLinkList, 0)
        self.py_stlink_list = [stLinkList[i] for i in range(stLinkListLen)]
        return self.py_stlink_list

    def getDfuDeviceList(self):
        global dfuList
        STM32_BOOT_VID = 0x0483
        STM32_BOOT_PID = 0xDF11
        dfuListLen = api_getDfuDeviceList(&dfuList, STM32_BOOT_VID, STM32_BOOT_PID)
        self.py_dfu_list = [dfuList[i] for i in range(dfuListLen)]
        return self.py_dfu_list

    def setOptionBytes(self):
        # return sendOptionBytesCmd(char* command);
        pass

    def initOptionBytesInterface(self):
        cdef peripheral_C* peripheral_c = <peripheral_C*> 0
        cdef bank_C * banks_c = <bank_C *> 0
        peripheral_c = api_initOptionBytesInterface()
        peripheral = {}
        peripheral["name"] = peripheral_c.name
        peripheral["description"] = peripheral_c.description
        peripheral["banksNbr"] = peripheral_c.banksNbr
        banks = []
        # for i in range(peripheral_c.banksNbr):
        #     banks.append(peripheral_c.banks[i])
        # peripheral["banks"] = banks
        return peripheral

    def displayOptionBytes(self) -> int:
        '''This function is crashed in .dll'''
        # return api_obDisplay()
        pass

    def connectStLink(self, int index=0) -> int :
        if index >= len(self.py_stlink_list):
            return -1
        # print(stLinkList[index])
        if 0 == stLinkList[index].accessPortNumber:  # assume this is an indication that the ST-Link is disconnected from the target.
            return -1
        cdef int err = api_connectStLink(stLinkList[index])
        # print(f'connectStLink: {err}')
        return err

    def connectDfuBootloader2(self, int index=0) -> int:
        if index >= len(self.py_dfu_list):
            return -1
        # print(dfuList[index])
        cdef dfuConnectParameters c_dfu_connect_parameters = dfuConnectParameters(usb_index = dfuList[index].usbIndex, rdu = 1)
        cdef int err = api_connectDfuBootloader2(c_dfu_connect_parameters)
        # print(f"connectDfuLink: {err}")
        return err


    def readMemory(self, unsigned int address, unsigned int byte_qty) -> bytearray:
        cdef unsigned char * data
        cdef int err = api_readMemory(address, &data, byte_qty)
        if err:
            return None
        bytes = bytearray()
        for i in range(byte_qty):
            bytes.append(data[i])
        return bytes

    def disconnect(self):
        api_disconnect()

    def readUnprotect(self):
        return api_readUnprotect()

    def getDeviceGeneralInf(self):
        cdef generalInf * p_general_inf = <generalInf *>0
        p_general_inf = api_getDeviceGeneralInf()
        return p_general_inf[0]

    def downloadFile(self, filePath, unsigned int address=0x08000000, unsigned int skipErase=0, unsigned int verify=1, binPath=''):
        cdef wchar_t* wfilePath = PyUnicode_AsWideCharString(filePath, NULL)
        cdef wchar_t* wbinPath = PyUnicode_AsWideCharString(binPath, NULL)
        print(f'downloadFile, filePath: {filePath}, address: {address}, skipErase: {skipErase}, verify: {verify}')
        return api_downloadFile(wfilePath, address, skipErase, verify, wbinPath)

    def reset(self, debugResetMode rstMode):
        return api_reset(rstMode)

    def execute(self, unsigned int address=0x08000000):
        return api_execute(address)

    def set_default_log_message_verbosity(self, val):
        global default_log_message_verbosity
        default_log_message_verbosity = val

    '''
    Check connection, USB and SWD, to microcontroller.
    Updates device_connected and stlink_connected
    '''
    def connection_update(self):

        self.c_device_connected = 1 == self.checkDeviceConnection()

        if not self.c_device_connected:
            self.disconnect()
            self.py_stlink_list = None
            self.c_stlink_connected = False
            self.py_dfu_list = None
            self.c_dfu_connected = False

        if self.py_stlink_list is None:
            self.getStLinkList()
            self.c_stlink_connected = len(self.py_stlink_list) > 0

        if self.py_dfu_list is None:
            self.getDfuDeviceList()
            self.c_dfu_connected = len(self.py_dfu_list) > 0

        if len(self.py_stlink_list) == 1 and not self.c_device_connected:
            self.connectStLink()

        if len(self.py_dfu_list) == 1 and not self.c_device_connected:
            self.connectDfuBootloader2()

        self.c_device_connected = 1 == self.checkDeviceConnection()

    def read_u8(self, adr_arg):
        cdef unsigned char * bytes
        cdef int err = api_readMemory(adr_arg, &bytes, 1)
        return None if err else int(bytes[0])

    def read_u16(self, adr_arg):
        cdef unsigned char * bytes
        cdef int err = api_readMemory(adr_arg, &bytes, 2)
        return None if err else int.from_bytes(bytes[0:2], byteorder='little', signed=False)

    def read_u32(self, adr_arg):
        cdef unsigned char * bytes
        cdef int err = api_readMemory(adr_arg, &bytes, 4)
        return None if err else int.from_bytes(bytes[0:4], byteorder='little', signed=False)

    def write_u8(self, adr_arg, val_arg: int):
        cdef unsigned char[4] bytes = int.to_bytes(val_arg, length=4, byteorder='little', signed=False)
        # <char*> cast required because writeMemory takes a char which is inconsistent with readMemory that takes unsigned char.
        cdef int err = api_writeMemory(adr_arg, <char*>&bytes[0], 1)

    def write_u16(self, adr_arg, val_arg: int):
        cdef unsigned char[4] bytes = int.to_bytes(val_arg, length=4, byteorder='little', signed=False)
        # <char*> cast required because writeMemory takes a char which is inconsistent with readMemory that takes unsigned char.
        cdef int err = api_writeMemory(adr_arg, <char*>&bytes[0], 2)

    def write_u32(self, adr_arg, val_arg):
        cdef unsigned char[4] bytes = int.to_bytes(val_arg, length=4, byteorder='little', signed=False)
        cdef int err = api_writeMemory(adr_arg, <char*>&bytes[0], 4)

    def read_str(self, adr_arg, char_qty):
        cdef unsigned char * bytes
        cdef int err = api_readMemory(adr_arg, &bytes, char_qty)
        return None if err else bytes.decode('iso-8859-1')  # 'utf-8')

    def read_f32(self, adr_arg):
        """
        Read float, single-precision, 4-bytes.
        """
        cdef unsigned char * bytes
        cdef int err = api_readMemory(adr_arg, &bytes, 4)
        return None if err else struct.unpack('<f', bytes[0:4])[0] # '<f' is little endian


@staticmethod
cdef void c_cb_InitProgressBar():
    global py_cb_InitProgressBar
    if py_cb_InitProgressBar is not None:
        (<object>py_cb_InitProgressBar)()
    else:
        str = f'InitProgressBar'
        size = len(str)
        c_cb_LogMessage(4, PyUnicode_AsWideCharString(str, &size))

# C variant of LogMessage will call the Python variant if it's been set.
@staticmethod
cdef void c_cb_LogMessage(int msgType,  const wchar_t* str):
    s = <object>PyUnicode_FromWideChar(str, -1)  # https://stackoverflow.com/a/16526775/101252
    global py_cb_LogMessage
    if py_cb_LogMessage is not None:
        (<object>py_cb_LogMessage)(msgType, s)
    else:
        global default_log_message_verbosity
        if default_log_message_verbosity > msgType:
            print(f'msgType: {msgType}, {s}')

@staticmethod
cdef void c_cb_LoadBar(int x, int n):
    global py_cb_LoadBar
    if py_cb_LoadBar is not None:
        (<object>py_cb_LoadBar)(x, n)
    else:
        str = f'lBar, x: {x}, n: {n} {(x * 100) / n:.2f}%'
        size = len(str)
        c_cb_LogMessage(4, PyUnicode_AsWideCharString(str, &size))


# Globals
cdef displayCallBacks display_cb_struct = displayCallBacks(logMessage = c_cb_LogMessage, initProgressBar = c_cb_InitProgressBar, loadBar = c_cb_LoadBar)
cdef debugConnectParameters * stLinkList = <debugConnectParameters *>0
cdef dfuDeviceInfo * dfuList = <dfuDeviceInfo *>0
cdef object py_cb_InitProgressBar = None
cdef object py_cb_LogMessage = None
cdef object py_cb_LoadBar = None
cdef int default_log_message_verbosity = 3



