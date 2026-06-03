import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

try:
    # Ruta absoluta o relativa al archivo JSON
    cred = credentials.Certificate(r'C:\Users\ADMIN\Documents\BSG\diseño-infraestructura-escalable\sesion1\backend-sesion1\bsg-sesion1-firebase-adminsdk-fbsvc-137f14c279.json')
    firebase_admin.initialize_app(cred)

    db = firestore.client()
    print("Conexión a Firestore exitosa.")
except Exception as e:
    print(f"Error al inicializar Firestore: {e}")
