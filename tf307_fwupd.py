#!/usr/bin/env python3

import argparse
import glob
import logging
import re
import os
import time
import serial
import subprocess

MYDIR = os.path.dirname(os.path.abspath(__file__))

SPI_SIZE = 32 * 1024 * 1024
SPI_LAYOUT = os.path.join(MYDIR, 'tf307.layout')
FIRMWARE_SECTIONS = ('scp', 'bl1', 'dtb', 'fip')

BM_SPI_SEL = 'BM_SPI_SEL'
ATX_PSON = 'ATX_PSON'
EN_1V8 = 'EN_1V8'

PREFLASH_COMMANDS = (BM_SPI_SEL, ATX_PSON, EN_1V8)

FLASH_CMD = 'sudo flashrom -p {} -c MT25QU256'
OLIMEX = 'olimex'
BAIKAL = 'baikal'
PROGRAMMERS = {
    OLIMEX: 'ft2232_spi:type=arm-usb-ocd-h,port=A,divisor=8',
    BAIKAL: 'ch341a_spi',
}

BOARD_REVISION_D = 'D'
BOARD_REVISION_AC = 'C' # A0 ... C

PINS_OLD = {
    BM_SPI_SEL: 7,
    ATX_PSON: 19,
    EN_1V8: 23,
}

PINS = {
    BM_SPI_SEL: 11,
    ATX_PSON: 16,
    EN_1V8: 26,
}

REPLIES = {
    BM_SPI_SEL: 'Set pin 11 (BM_SPI_SEL)',
    ATX_PSON: 'Set pin 16 (ATX_PSON)',
    EN_1V8: 'Set pin 26 (EN_1V8)',
}

REPLIES_OLD = {
    BM_SPI_SEL: 'Set pin[7] BM_SPI_SEL',
    ATX_PSON: 'Set pin[19] ATX_PSON',
    EN_1V8: 'Set pin[23] EN_1V8',
}

PREPARE = {
        BOARD_REVISION_D: (PINS, REPLIES),
        BOARD_REVISION_AC: (PINS_OLD, REPLIES_OLD)
}


BMC_PROMPT = b'>:'


def guess_board_revision(bmc):
    logging.info('guessing board revision')
    AVAILABLE_PINS = 'available pins:'

    logging.info('run "pin list" BMC command')
    bmc.write(b'pins list\n')
    bmc.read_until() # discard echo
    header = bmc.read_until().strip().decode('utf-8')
    if header.lower() != AVAILABLE_PINS:
        logging.error('got: "%s", expected "%s"', header, AVAILABLE_PINS)
        raise RuntimeError('Unexpected reply to "pins list"')

    out = bmc.read_until(BMC_PROMPT)
    pins_list = [line.decode('utf-8') for line in out.split(b'\r\n')]
    for line in pins_list:
        logging.debug('guess_board_revision: %s', line)
    d_rx = re.compile(r'^11:\s*OUT\s+BM_SPI_SEL.*$')
    ac_rx = re.compile(r'^07:\s*OUT\s+BM_SPI_SEL.*$')
    is_d = any(d_rx.match(line) is not None for line in pins_list)
    is_ac = any(ac_rx.match(line) is not None for line in pins_list)

    if is_d and is_ac:
        logging.error('board has pins from rev A0-C and rev D')
        raise RuntimeError('Ouch, looks like **both** rev A0-C and rev D')
    elif is_d:
        revision = BOARD_REVISION_D
    elif is_ac:
        revision = BOARD_REVISION_AC
    else:
        raise RuntimeError('Unable to figure out board revision')

    logging.info('board revision: %s', revision)
    return revision


def prepare(bmc, revision=None):
    if revision is None:
        revision = guess_board_revision(bmc)

    pins, replies = PREPARE[revision]

    logging.info('preparing to flash')
    for cmd in PREFLASH_COMMANDS:
        code = b'pins set %d\n' % pins[cmd]
        logging.info('running BMC command "%s"', code)
        bmc.write(code)
        bmc.read_until() # skip echo
        reply = bmc.read_until().strip()
        expected = replies[cmd]
        if reply != expected.encode('utf-8'):
            raise RuntimeError('Got "%s" in reply to "%s"' % (reply, code))
    # otherwise flashrom fails to detect the chip
    logging.info('waiting for BMC to complete preparations')
    time.sleep(3)


def renew_sudo_timestamp():
    cmd = ['sudo', '/bin/true']
    logging.info('Renewing sudo stamp: "%s"', ' '.join(cmd))
    subprocess.check_call(cmd)


def flash(img, programmer=BAIKAL, fast=False):
    renew_sudo_timestamp()
    cmd = FLASH_CMD.format(PROGRAMMERS[programmer]).split()
    cmd += ['-w', img]
    if fast:
        logging.info('fast mode: skipping FAT section')
        cmd += ['-l', SPI_LAYOUT]
        for section in FIRMWARE_SECTIONS:
            cmd += ['-i', section]
        cmd += ['--noverify-all']
    logging.info('flashing file "%s" with command "%s"', img,  cmd)
    ti = time.perf_counter()
    subprocess.check_call(cmd)
    tf = time.perf_counter()
    logging.info('successfully completed flashing in %.2f sec', tf - ti)
    time.sleep(1)


def finish(bmc):
    logging.info('finishing')
    logging.info('running "pins bootseq" BMC command')
    bmc.write(b'pins bootseq\n')
    logging.info('wait for BMC to complete the boot sequence')
    time.sleep(0.5)
    bmc.read_until() # skip the echo
    reply = bmc.read_until()
    if reply != b'\x1b[32mL: [SHELL] Starting boot sequence\x1b[0m\r\n':
        logging.error('finish: unexpected reply "%s"', reply)
        raise RuntimeError('Got "%s" as reply to "pins bootseq"' % reply)

    expected = b'\x1b[32mL: [SHELL] Boot sequence finished\x1b[0m\r\n'
    while reply != expected:
        logging.info('finish: reading more BMC output')
        reply = bmc.read_until()

    logging.info('switching the board off')
    logging.info('running "pins board_off" BMC command')
    bmc.write(b'pins board_off\n')
    bmc.read_until()
    reply = bmc.read_until()
    if reply != b'\x1b[32mL: [SHELL] Pins are reset to board off state\x1b[0m\r\n':
        raise RuntimeError('Got "%s" in reply to "pins board_off"' % reply)

    reply = bmc.read_until()
    if reply == '>:\x1b[32mL: [BM1BM1_PINS] Wake up requested\x1b[0m\r\n':
        bmc.read_until()
        bmc.read_until()

    logging.info('retrying "pins board_off" BMC command')
    bmc.write(b'pins board_off\n')
    bmc.read_until()
    reply = bmc.read_until()


def upd_firmware(bmcpath, img,
                 programmer=OLIMEX,
                 revision='auto',
                 fast=False):
    if revision == 'auto':
        revision = None
    if os.stat(img).st_size != SPI_SIZE:
        subprocess.check_call(['truncate', '-c', '-s', str(SPI_SIZE), img])
    renew_sudo_timestamp()
    with serial.Serial(bmcpath, 115200, timeout=10) as bmc:
        prepare(bmc, revision=revision)
        flash(img, programmer=programmer, fast=fast)
        finish(bmc)


def print_board_revision(bmcpath):
    with serial.Serial(bmcpath, 115200, timeout=10) as bmc:
        print(guess_board_revision(bmc))


def udev_query(dev):
    cmd = 'udevadm info -x -q all'.split() + [dev]
    logging.debug('running "%s"', ' '.join(cmd))
    out = subprocess.check_output(cmd, encoding='utf-8')
    return [l.strip() for l in out.strip().split('\n')]


def detect_ft232r():
    ID_MODEL = 'E: ID_MODEL=FT232R_USB_UART'
    usb_uarts = glob.glob('/dev/ttyUSB[0-9]*')
    logging.debug('USB UART device nodes: %s', ', '.join(usb_uarts))
    candidates = []
    for dev in usb_uarts:
        info = udev_query(dev)
        if ID_MODEL in info:
            logging.info('%s looks like FT232 USB UART', dev)
            candidates.append(dev)
        else:
            logging.debug('%s is not FT232 USB UART', dev)

    if len(candidates) == 0:
        logging.error('No FT232 USB UARTs have been found')
        raise RuntimeError('NO_USB_UARTS')
    elif len(candidates) > 1:
        logging.error('%d FT232 USB UARTs have been found', len(candidates))
        raise RuntimeError('MANY_USB_UARTS')
    else:
        logging.info('BMC device node: %s', candidates[0])
        return candidates[0]


def detect_stlink():
    ID_MODEL = 'E: ID_MODEL=STM32_STLink'
    usb_uarts = glob.glob('/dev/ttyACM[0-9]*')
    logging.debug('USB UART device nodes: %s', ', '.join(usb_uarts))
    candidates = []
    for dev in usb_uarts:
        info = udev_query(dev)
        if ID_MODEL in info:
            logging.info('%s looks like STLink USB UART', dev)
            candidates.append(dev)
        else:
            logging.debug('%s is not STLink USB UART', dev)

    if len(candidates) == 0:
        logging.error('No STLink USB UARTs have been found')
        raise RuntimeError('NO_USB_UARTS')
    elif len(candidates) > 1:
        logging.error('%d STLink USB UARTs have been found', len(candidates))
        raise RuntimeError('MANY_USB_UARTS')
    else:
        logging.info('BMC device node: %s', candidates[0])
        return candidates[0]


def guess_bmc_devnode(programmer):
    if programmer == OLIMEX:
        logging.debug('Trying to auto-detect FT232 USB UART')
        return detect_ft232r()
    elif programmer == BAIKAL:
        return detect_stlink()
    else:
        logging.error("Don't know how to detect BMC with %s", programmer)
        raise RuntimeError('BMC_AUTODETECT_DUNNO')


def single_usb_device_present(usbid):
    cmd = ['lsusb', '-d', usbid]
    try:
        logging.debug('running lsusb: "%s"', ' '.join(cmd))
        out = subprocess.check_output(cmd, encoding='utf-8')
        out = out.strip().split('\n')
        count = len(out)
    except subprocess.CalledProcessError as err:
        logging.debug('lsusb returned %d', err.returncode)
        # lsusb returns non-zero if the specified device is not found
        count = 0
    if count == 0:
        logging.info('No USB devices with id "%s"', usbid)
    elif count > 1:
        logging.info('%d USB devices with id "%s"', count, usbid)
    return count == 1


def detect_baikail_programmer():
    USB_IDS = [
        '1a86:5512', # QinHeng Electronics CH341
        '0483:374b', # STMicroelectronics ST-LINK/V2.1
        '1a40:0101', # Terminus Technology Inc. Hub
    ]
    return all(single_usb_device_present(usbid) for usbid in USB_IDS)


def detect_olimex_programmer():
    USB_IDS = [
        '15ba:002b',
    ]
    return any(single_usb_device_present(usbid) for usbid in USB_IDS)


def guess_programmer():
    logging.debug('Trying to detect OLIMEX programmer')
    if detect_olimex_programmer():
        logging.info('Found OLIMEX ARM-USB-OCD-H programmer')
        return OLIMEX
    logging.debug('Trying to detect BAIKAL programmer')
    if detect_baikail_programmer():
        logging.info('Found Baikal Electronics custom programmer')
        return BAIKAL
    else:
        raise RuntimeError('Failed to autodetect programmer')


def sanity_check():
    PROGRAMS = {
        'flashrom': 'flashrom',
        'lsusb': 'usbutils',
        'sudo': 'sudo',
        'udevadm': 'udev',
    }
    missing = []
    for prog, package in PROGRAMS.items():
        try:
            logging.debug('checking for "%s"', prog)
            subprocess.check_output([prog, '--version'])
        except FileNotFoundError:
            missing.append(prog)

    for prog in missing:
        logging.error('"%s" is missing, please "apt-get install %s"',
                      prog, package)
    if len(missing) > 0:
        raise RuntimeError('MISSING_REQUIRED_PROGRAM')


def main():
    parser = argparse.ArgumentParser(description='Flash TF307 board firmware')
    parser.add_argument('-t', '--tty', help='bmc console device',
                        default='auto')
    parser.add_argument('-p', '--programmer', help='programmer type',
            choices=[BAIKAL, OLIMEX, 'auto'], default='auto')
    parser.add_argument('-r', '--revision', help='board revision',
            choices=[BOARD_REVISION_AC, BOARD_REVISION_D, 'auto'],
            default='auto')
    parser.add_argument('--guess-revision-only', action='store_true',
                        help="Print board revision, don't touch firmware")
    parser.add_argument('-f', '--full', help="flash complete image (FAT section is skipped by default)",
                        action='store_true', default=False)
    parser.add_argument('-v', '--verbose', action='count', default=0,
                        help='Verbose execution mode')
    parser.add_argument('file', help='firmware image file')
    args = parser.parse_args()

    level = logging.INFO
    if args.verbose >= 1:
        level = logging.DEBUG
    logging.basicConfig(format='%(levelname)s:%(message)s', level=level)

    sanity_check()

    if args.programmer == 'auto':
        args.programmer = guess_programmer()

    if args.tty == 'auto':
        args.tty = guess_bmc_devnode(args.programmer)

    if args.guess_revision_only:
        print_board_revision(args.tty)
        return

    upd_firmware(args.tty, args.file,
                 programmer=args.programmer,
                 revision=args.revision,
                 fast=not(args.full))


if __name__ == '__main__':
    main()
