#!/usr/bin/env bash
# Equivalente de INSTALAR.bat para macOS y Linux:  ./instalar.sh   (o  bash instalar.sh)
# Prepara Python 3.12 + MuJoCo + OpenCV + cerebros en workshop-ia-fisica/.venv y comprueba todo el taller.
# Las wheels de wheels/ son de Windows: aqui solo se usa la de bam (Python puro); el resto se baja de PyPI (hace falta Internet).
cd "$(dirname "$0")"
RAIZ="$(pwd)"
LOG="$RAIZ/instalar_log.txt"
: > "$LOG"

instalar() {
  set -e
  cd "$RAIZ/workshop-ia-fisica"
  echo "== 1/4 Comprobando Python 3.12 =="
  PY=""
  for c in python3.12 /opt/homebrew/bin/python3.12 /usr/local/bin/python3.12; do
    if command -v "$c" >/dev/null 2>&1; then PY="$(command -v "$c")"; break; fi
  done
  if [ -z "$PY" ]; then
    echo "Python 3.12 no encontrado. Intentando instalarlo..."
    if command -v brew >/dev/null 2>&1; then
      brew install python@3.12 && PY="$(brew --prefix)/bin/python3.12"
    elif command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y python3.12 python3.12-venv || {
        sudo apt-get install -y software-properties-common && sudo add-apt-repository -y ppa:deadsnakes/ppa \
          && sudo apt-get update && sudo apt-get install -y python3.12 python3.12-venv; }
      PY="$(command -v python3.12 || true)"
    fi
    if [ -z "$PY" ] && command -v uv >/dev/null 2>&1; then
      uv python install 3.12 && PY="$(uv python find 3.12)"
    fi
    if [ -z "$PY" ]; then
      echo "NO SE PUDO INSTALAR PYTHON 3.12. macOS: 'brew install python@3.12' | Ubuntu: 'sudo apt install python3.12 python3.12-venv'. Luego vuelve a ejecutar."
      exit 1
    fi
  fi
  "$PY" --version

  echo "== 2/4 Creando entorno virtual .venv =="
  "$PY" -m venv .venv
  VPY="$RAIZ/workshop-ia-fisica/.venv/bin/python"

  echo "== 3/4 Instalando librerias (PyPI + bam desde wheels/) =="
  "$VPY" -m pip install -r requirements.txt
  # Teclado: los ejercicios usan msvcrt (solo Windows); en Linux/macOS importan este sustituto para la terminal.
  cp "$RAIZ/posix/msvcrt_posix.py" "$("$VPY" -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')/"

  echo "== 4/4 Verificando =="
  "$VPY" check_setup.py
}

echo "===== Instalando el entorno del taller. Puede tardar unos minutos. ====="
( instalar ) 2>&1 | tee -a "$LOG"
echo
echo "===== Comprobando todo el taller ====="
workshop-ia-fisica/.venv/bin/python check_taller.py 2>&1 | tee -a "$LOG"
echo
echo "Si arriba pone TODO LISTO, el PC esta preparado. Si no, enviar instalar_log.txt al ponente."
