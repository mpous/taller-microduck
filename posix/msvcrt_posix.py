"""Sustituto minimo de 'msvcrt' (teclado de Windows) para Linux y macOS.

instalar.sh lo copia al .venv; los ejercicios escritos para Windows hacen 'import msvcrt_posix as msvcrt' si no hay msvcrt,
y kbhit()/getwch() funcionan igual. (No se llama 'msvcrt': subprocess lo usaria para creer que esta en Windows.) Las flechas de la terminal (ESC [ A/B/C/D) se traducen a lo que da Windows: '\\xe0' + H/P/M/K.
"""
import atexit, os, select, sys, termios, tty

_ARROWS = {"A": "H", "B": "P", "C": "M", "D": "K"}
_pendiente = []
_fd = sys.stdin.fileno() if sys.stdin and sys.stdin.isatty() else -1
_old = None


def _preparar():
    # Modo cbreak (tecla a tecla, sin eco) la primera vez que se usa el teclado; se restaura al salir.
    global _old
    if _fd < 0 or _old is not None:
        return
    _old = termios.tcgetattr(_fd)
    tty.setcbreak(_fd)
    atexit.register(termios.tcsetattr, _fd, termios.TCSADRAIN, _old)


def _hay(timeout):
    return _fd >= 0 and bool(select.select([_fd], [], [], timeout)[0])


def _leer1():
    data = os.read(_fd, 1)
    return data.decode(errors="ignore") if data else ""


def kbhit():
    _preparar()
    return bool(_pendiente) or _hay(0)


def getwch():
    _preparar()
    if _pendiente:
        return _pendiente.pop(0)
    if _fd < 0:
        return ""
    ch = _leer1()
    if ch == "\x1b" and _hay(0.05) and _leer1() == "[" and _hay(0.05):
        final = _ARROWS.get(_leer1())
        if final:
            _pendiente.append(final)
            return "\xe0"
        return ""
    return "\r" if ch == "\n" else ch


getch = lambda: getwch().encode()
