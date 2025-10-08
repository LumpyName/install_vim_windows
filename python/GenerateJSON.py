import json
import os
from datetime import datetime
from typing import Any, Dict, Optional


class GenerateJSON:
    """
    Clase para gestionar archivos JSON con estructura de claves que incluyen
    value, start_date y end_date.
    
    Estructura esperada del JSON:
    {
        "key_name": {
            "value": "contenido",
            "start_date": "dd-mm-yyyy HH:MM:SS",
            "end_date": "dd-mm-yyyy HH:MM:SS" o "No set date"
        }
    }
    """
    
    def __init__(self, filename: str):
        """
        Inicializa el gestor de JSON.
        
        Args:
            filename (str): Nombre del archivo JSON (con o sin extensión .json)
        """
        # Asegurar que el nombre tenga extensión .json
        if not filename.endswith('.json'):
            filename += '.json'
        
        self.filename = filename
        self.data = {}
        
        # Cargar el archivo si existe
        if os.path.exists(self.filename):
            self._load()
    
    def _load(self):
        """Carga el contenido del archivo JSON existente."""
        try:
            with open(self.filename, 'r', encoding='utf-8') as file:
                self.data = json.load(file)
                print(f"✓ Archivo '{self.filename}' cargado correctamente.")
        except json.JSONDecodeError:
            print(f"⚠ El archivo '{self.filename}' no tiene formato JSON válido. Se iniciará vacío.")
            self.data = {}
        except Exception as e:
            print(f"✗ Error al cargar el archivo: {e}")
            self.data = {}
    
    def _get_current_datetime(self) -> str:
        """
        Retorna la fecha y hora actual en formato dd-mm-yyyy HH:MM:SS
        
        Returns:
            str: Fecha y hora formateada
        """
        return datetime.now().strftime("%d-%m-%Y %H:%M:%S")
    
    def key(self, key_name: str, value: Any, end_date: str = "No set date") -> None:
        """
        Agrega o modifica una clave en el JSON.
        
        Si la clave existe, actualiza su value y end_date.
        Si la clave no existe, la crea con start_date automático.
        
        Args:
            key_name (str): Nombre de la clave a crear/modificar
            value (Any): Contenido/valor de la clave
            end_date (str, optional): Fecha de finalización. Default: "No set date"
        
        Ejemplo:
            >>> gen = GenerateJSON("config.json")
            >>> gen.key("TOKEN_API", value="abc123xyz", end_date="31-12-2025")
        """
        if key_name in self.data:
            # Si la clave existe, modificarla (mantener start_date original)
            self.data[key_name]["value"] = value
            self.data[key_name]["end_date"] = end_date
            print(f"✓ Clave '{key_name}' actualizada.")
        else:
            # Si no existe, crearla con start_date automático
            self.data[key_name] = {
                "value": value,
                "start_date": self._get_current_datetime(),
                "end_date": end_date
            }
            print(f"✓ Clave '{key_name}' creada exitosamente.")
    
    def get(self, key_name: str) -> Optional[Dict[str, Any]]:
        """
        Obtiene toda la información de una clave específica.
        
        Args:
            key_name (str): Nombre de la clave a buscar
        
        Returns:
            dict o None: Diccionario con value, start_date y end_date, o None si no existe
        
        Ejemplo:
            >>> gen = GenerateJSON("config.json")
            >>> info = gen.get("TOKEN_API")
            >>> print(info)
            {'value': 'abc123xyz', 'start_date': '07-10-2025 14:30:45', 'end_date': '31-12-2025'}
        """
        if key_name in self.data:
            return self.data[key_name]
        else:
            print(f"⚠ La clave '{key_name}' no existe en el JSON.")
            return None
    
    def delete(self, key_name: str) -> bool:
        """
        Elimina una clave del JSON.
        
        Args:
            key_name (str): Nombre de la clave a eliminar
        
        Returns:
            bool: True si se eliminó, False si no existía
        """
        if key_name in self.data:
            del self.data[key_name]
            print(f"✓ Clave '{key_name}' eliminada.")
            return True
        else:
            print(f"⚠ La clave '{key_name}' no existe.")
            return False
    
    def list_keys(self) -> list:
        """
        Lista todas las claves disponibles en el JSON.
        
        Returns:
            list: Lista con los nombres de todas las claves
        """
        return list(self.data.keys())
    
    def save(self) -> None:
        """
        Guarda todos los cambios en el archivo JSON.
        Si el archivo existe, lo sobrescribe.
        Si no existe, lo crea.
        
        Ejemplo:
            >>> gen = GenerateJSON("config.json")
            >>> gen.key("TOKEN_GTE", value="token_secreto_123")
            >>> gen.save()
        """
        try:
            with open(self.filename, 'w', encoding='utf-8') as file:
                json.dump(self.data, file, indent=2, ensure_ascii=False)
            print(f"✓ Cambios guardados en '{self.filename}'.")
        except Exception as e:
            print(f"✗ Error al guardar el archivo: {e}")
    
    def __repr__(self) -> str:
        """Representación en string del objeto."""
        return f"GenerateJSON(filename='{self.filename}', keys={len(self.data)})"


# ============================================
# EJEMPLO DE USO
# ============================================

if __name__ == "__main__":
    print("=" * 60)
    print("EJEMPLO DE USO - GenerateJSON")
    print("=" * 60)
    
    # 1. Crear instancia del gestor
    print("\n1. Creando gestor para 'configuracion.json'...")
    generated_json = GenerateJSON("configuracion.json")
    
    # 2. Agregar claves
    print("\n2. Agregando claves...")
    generated_json.key("TOKEN_GTE", value="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9", end_date="31-12-2025")
    generated_json.key("API_KEY", value="sk-1234567890abcdef", end_date="No set date")
    generated_json.key("DATABASE_URL", value="postgresql://user:pass@localhost/db")
    
    # 3. Obtener información de una clave
    print("\n3. Consultando información de 'TOKEN_GTE'...")
    token_info = generated_json.get("TOKEN_GTE")
    if token_info:
        print(f"   Value: {token_info['value']}")
        print(f"   Start Date: {token_info['start_date']}")
        print(f"   End Date: {token_info['end_date']}")
    
    # 4. Modificar una clave existente
    print("\n4. Modificando 'API_KEY'...")
    generated_json.key("API_KEY", value="sk-nuevo_token_987654", end_date="15-06-2026")
    
    # 5. Listar todas las claves
    print("\n5. Listando todas las claves...")
    keys = generated_json.list_keys()
    print(f"   Claves disponibles: {keys}")
    
    # 6. Guardar cambios
    print("\n6. Guardando cambios en el archivo...")
    generated_json.save()
    
    print("\n" + "=" * 60)
    print("¡Ejemplo completado! Revisa el archivo 'configuracion.json'")
    print("=" * 60)
