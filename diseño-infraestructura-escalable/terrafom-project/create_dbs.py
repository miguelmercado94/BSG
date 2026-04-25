import pg8000.native

host = 'bsg-rds-instance.ce9qm2yy2gs8.us-east-1.rds.amazonaws.com'
port = 5432
user = 'bsg_admin'
password = 'PasswordSeguro123'

print("Conectando a postgres...")
try:
    con = pg8000.native.Connection(user=user, password=password, host=host, port=port, database='postgres')
    con.run("CREATE DATABASE bsg_security;")
    print("Database bsg_security creada.")
except Exception as e:
    print(f"Aviso bsg_security: {e}")
finally:
    try:
        con.close()
    except:
        pass

try:
    con = pg8000.native.Connection(user=user, password=password, host=host, port=port, database='postgres')
    con.run("CREATE DATABASE docviz;")
    print("Database docviz creada.")
except Exception as e:
    print(f"Aviso docviz: {e}")
finally:
    try:
        con.close()
    except:
        pass

print("Conectando a docviz para crear extension vector...")
try:
    con = pg8000.native.Connection(user=user, password=password, host=host, port=port, database='docviz')
    con.run("CREATE EXTENSION IF NOT EXISTS vector;")
    print("Extension vector creada en docviz.")
except Exception as e:
    print(f"Error creando extension: {e}")
finally:
    try:
        con.close()
    except:
        pass
