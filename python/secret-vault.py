#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Secret Vault - Gestor de claves encriptadas con Fernet
Guarda tokens, API keys y secretos de forma segura

REQUISITOS:
- pip install cryptography
- Archivo GenerateJSON.py con la clase GenerateJSON
"""

import os
import base64
import hashlib
import getpass
import re
from datetime import datetime

from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

# Importar la clase GenerateJSON existente
from GenerateJSON import GenerateJSON


def generar_clave_desde_password(password, salt=None):
    # Generar salt aleatorio si no se proporciona
    if salt is None:
        salt = os.urandom(16)
    
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
    return key, salt


def encriptar_contenido(contenido, password):
    clave, salt = generar_clave_desde_password(password)
    fernet = Fernet(clave)
    contenido_encriptado = fernet.encrypt(contenido.encode())
    # Retornar salt + contenido encriptado
    return base64.urlsafe_b64encode(salt + contenido_encriptado).decode()


def desencriptar_contenido(contenido_encriptado, password):
    try:
        # Decodificar y extraer salt
        data = base64.urlsafe_b64decode(contenido_encriptado.encode())
        salt = data[:16]
        encrypted = data[16:]
        
        # Generar clave con el salt original
        clave, _ = generar_clave_desde_password(password, salt)
        fernet = Fernet(clave)
        contenido = fernet.decrypt(encrypted)
        return contenido.decode()
    except:
        return None


def validar_fecha(fecha_str):
    """
    Valida formato dd-mm-yyyy
    Retorna True si es valido, False si no
    """
    if not fecha_str or fecha_str.strip() == "":
        return True  # Fecha vacia es valida (se convierte a "No set date")
    
    # Patron dd-mm-yyyy
    patron = r'^(\d{2})-(\d{2})-(\d{4})$'
    match = re.match(patron, fecha_str)
    
    if not match:
        return False
    
    try:
        dia, mes, anio = map(int, match.groups())
        datetime(anio, mes, dia)
        return True
    except ValueError:
        return False


def interfaz_interactiva():
    """Interfaz principal para agregar claves"""
    print("\n" + "=" * 70)
    print(" SECRET VAULT - Gestor de Claves Encriptadas".center(70))
    print("=" * 70)
    
    # Pedir password de encriptacion (oculta)
    print("\n[PASO 1] Configuracion de seguridad")
    password = getpass.getpass("Decryption key  : ")
    
    if not password:
        print("[ERROR] La clave de desencriptacion no puede estar vacia")
        return
    
    print("\n[PASO 2] Agregar claves secretas")
    print("[INFO] Presiona Enter en 'Key name' para terminar\n")
    
    # Crear gestor JSON usando TU clase
    json_manager = GenerateJSON("EncryptedDates.json")
    
    # Contador de claves agregadas
    claves_agregadas = 0
    
    while True:
        # Pedir nombre de clave
        key_name = input("Key name        : ").strip()
        
        # Si esta vacio, terminar
        if not key_name:
            if claves_agregadas == 0:
                print("\n[INFO] No se agregaron claves. Saliendo...")
            break
        
        # Pedir contenido (OBLIGATORIO)
        while True:
            key_content = input("Key content     : ").strip()
            if key_content:
                break
            print("[ERROR] Este campo no puede estar vacio")
            print()
        
        # Pedir fecha de expiracion (OPCIONAL)
        while True:
            end_date_input = input("End_date        : ").strip()
            
            # Si esta vacio, es valido (se usara "No set date")
            if not end_date_input:
                end_date_input = "No set date"
                break
            
            # Validar formato
            if validar_fecha(end_date_input):
                break
            else:
                print("[ERROR] Formato invalido. Use dd-mm-yyyy (ejemplo: 31-12-2025)")
                print("[INFO] O presione Enter para omitir")
        
        # Encriptar el contenido
        contenido_encriptado = encriptar_contenido(key_content, password)
        
        # Guardar en JSON usando TU clase
        json_manager.key(key_name, value=contenido_encriptado, end_date=end_date_input)
        
        claves_agregadas += 1
        print()  # Salto de linea
    
    # Guardar archivo JSON
    if claves_agregadas > 0:
        print("\n" + "=" * 70)
        json_manager.save()
        print(f"[OK] Se agregaron/actualizaron {claves_agregadas} clave(s)")
        print("=" * 70)
        
        # Mostrar resumen
        mostrar_resumen(json_manager)


def ver_claves():
    """Ver claves almacenadas (desencriptadas)"""
    print("\n" + "=" * 70)
    print(" VER CLAVES ALMACENADAS".center(70))
    print("=" * 70)
    
    # Verificar si existe el archivo
    if not os.path.exists("EncryptedDates.json"):
        print("\n[ERROR] No existe el archivo 'EncryptedDates.json'")
        print("[INFO] Primero debes agregar claves")
        return
    
    # Pedir password
    password = getpass.getpass("\nDecryption key  : ")
    
    # Cargar JSON
    json_manager = GenerateJSON("EncryptedDates.json")
    
    keys = json_manager.list_keys()
    if not keys:
        print("\n[INFO] No hay claves almacenadas")
        return
    
    # Mostrar claves desencriptadas
    print("\n" + "=" * 70)
    print("CLAVES DESENCRIPTADAS")
    print("=" * 70)
    
    for key_name in keys:
        info = json_manager.get(key_name)
        if info:
            contenido_desencriptado = desencriptar_contenido(info['value'], password)
            
            if contenido_desencriptado is None:
                print(f"\n[ERROR] No se pudo desencriptar '{key_name}'")
                print("        Password incorrecta o datos corruptos")
            else:
                print(f"\nKey name        : {key_name}")
                print(f"Key content     : {contenido_desencriptado}")
                print(f"Start date      : {info['start_date']}")
                print(f"End date        : {info['end_date']}")
    
    print("=" * 70)


def mostrar_resumen(json_manager=None):
    """Muestra resumen de claves sin desencriptar"""
    if json_manager is None:
        if not os.path.exists("EncryptedDates.json"):
            print("\n[ERROR] No existe el archivo 'EncryptedDates.json'")
            return
        json_manager = GenerateJSON("EncryptedDates.json")
    
    keys = json_manager.list_keys()
    
    if not keys:
        print("\n[INFO] No hay claves almacenadas")
        return
    
    print("\n" + "=" * 70)
    print("RESUMEN DE CLAVES (SIN DESENCRIPTAR)")
    print("=" * 70)
    
    for key_name in keys:
        info = json_manager.get(key_name)
        if info:
            print(f"\nKey name        : {key_name}")
            print(f"Key content     : {'*' * 30} (encriptado)")
            print(f"Start date      : {info['start_date']}")
            print(f"End date        : {info['end_date']}")
    
    print("=" * 70)


def menu_principal():
    """Menu principal"""
    while True:
        print("\n" + "=" * 70)
        print(" SECRET VAULT - Menu Principal".center(70))
        print("=" * 70)
        print("\n1. Agregar/Modificar claves")
        print("2. Ver claves almacenadas (desencriptadas)")
        print("3. Ver resumen (sin desencriptar)")
        print("4. Salir")
        
        opcion = input("\nSelecciona una opcion: ").strip()
        
        if opcion == "1":
            interfaz_interactiva()
        elif opcion == "2":
            ver_claves()
        elif opcion == "3":
            mostrar_resumen()
        elif opcion == "4":
            print("\n[INFO] Saliendo... Hasta luego!")
            break
        else:
            print("\n[ERROR] Opcion invalida")


if __name__ == "__main__":
    menu_principal()
