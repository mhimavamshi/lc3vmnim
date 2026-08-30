import std/termios
import std/posix

var originalTio: Termios

proc disableInputBuffering*() =
    # NOTE: -1 is returned for error
    discard tcGetAttr(STDIN_FILENO, addr originalTio) 

    var newTio = originalTio
    newTio.c_lflag = newTio.c_lflag and not (ICANON or ECHO)

    discard tcSetAttr(STDIN_FILENO, TCSANOW, addr newTio)

proc restoreInputBuffering*() =
    discard tcSetAttr(STDIN_FILENO, TCSANOW, addr originalTio)

#[
Replace with std/selectors later, maybe
]#
proc checkKey*(): bool =
    var readfds: TFdSet
    FD_ZERO(readfds)
    FD_SET(STDIN_FILENO, readfds)

    var timeout = Timeval(
        tv_sec: Time(0),
        tv_usec: 0
    )

    result = select(
        STDIN_FILENO + 1,
        addr readfds,
        nil,
        nil,
        addr timeout
    ) > 0

proc readKey*(): uint16 =
    var c: char
    let n = read(STDIN_FILENO, addr c, 1)

    if n == 1:
        return uint16(ord(c))

    return 0