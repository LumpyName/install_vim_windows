" ========================
"   CONFIGURACIÓN BÁSICA
" ========================
set nobomb              " Codificación a UTF-8 sin BOM.
set number              " Mostrar números de línea
set relativenumber      " Números relativos para navegación
set tabstop=4           " Tamaño de tabulaciones
set shiftwidth=4        " Tamaño de indentación
set expandtab           " Usar espacios en lugar de tabs
set autoindent          " Mantener indentación automática
set smartindent         " Indentación inteligente
set encoding=utf-8      " Codificación UTF-8
set fileencoding=utf-8  " Codificación de archivos
set scrolloff=5         " Margen al hacer scroll
set cursorline          " Resaltar línea actual
set showcmd             " Mostrar comandos abajo
set wildmenu            " Menú de autocompletado
set nobackup            " No crear archivos de respaldo
set nowritebackup       " No crear respaldo al guardar
set noswapfile          " No crear archivos swap

" ========================
"   COLOR Y ESTILO
" ========================
syntax on               " Activar resaltado de sintaxis
set termguicolors       " Colores verdaderos si tu terminal lo soporta
colorscheme desert      " Tema de colores (puedes cambiarlo)

" ========================
"   PYTHON CONFIG
" ========================
let g:python3_host_prog = '/usr/bin/python3'  " Ruta a tu Python 3
" Si estás en Windows, usa algo como:
" let g:python3_host_prog = 'C:/Python311/python.exe'

" ========================
"   MAPAS DE TECLAS ÚTILES
" ========================
nnoremap <F5> :w<CR>:tabnew<CR>:terminal python3 %<CR>   " Ejecutar script Python con F5
nnoremap <C-s> :w<CR>                 " Guardar con Ctrl+S
nnoremap <C-q> :q<CR>                 " Salir con Ctrl+Q
nnoremap <C-h> :nohlsearch<CR>        " Limpiar búsqueda con Ctrl+H

" ========================
"   BÚSQUEDA Y NAVEGACIÓN
" ========================
set incsearch            " Buscar mientras escribes
set ignorecase           " Ignorar mayúsculas
set smartcase            " Pero respetarlas si usas mayúsculas
set hlsearch             " Resaltar resultados

" ========================
"   PORTABILIDAD
" ========================
if has('mouse')
  set mouse=a            " Activar uso del mouse
endif

" ========================
"   AUTOCOMPLETADO BÁSICO
" ========================
set completeopt=menuone,noinsert,noselect
set omnifunc=syntaxcomplete#Complete

" ========================
"   FORMATO AUTOMÁTICO
" ========================
autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4
autocmd BufWritePre *.py :silent! %s/\s\+$//e   " Eliminar espacios al final
