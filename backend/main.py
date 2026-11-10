from fastapi import FastAPI
from pydantic import BaseModel
import requests
import pyodbc

app = FastAPI()

# SQL Server Bağlantı Ayarları
DB_CONNECTION_STRING = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;"
    "DATABASE=FinansAbonelikDB;"
    "Trusted_Connection=yes;"
)

# Gelen abonelik verisinin şemasını (modelini) tanımlıyoruz
class AbonelikModel(BaseModel):
    AbonelikAdi: str
    Kategori: str
    Ucret: float
    ParaBirimi: str
    BaslangicTarihi: str
    YenilemePeriyodu: str

@app.get("/")
def ana_sayfa():
    return {"mesaj": "Finans Abonelik Takip Backend Servisi Çalışıyor!"}

@app.get("/db-test")
def veritabani_test():
    try:
        baglanti = pyodbc.connect(DB_CONNECTION_STRING)
        cursor = baglanti.cursor()
        cursor.execute("SELECT @@VERSION;")
        surum = cursor.fetchone()[0]
        baglanti.close()
        return {
            "durum": "Başarılı",
            "mesaj": "SQL Server veritabanı bağlantısı başarılı!",
            "sql_versiyon": surum
        }
    except Exception as e:
        return {
            "durum": "Hata",
            "mesaj": "Veritabanına bağlanılamadı!",
            "detay": str(e)
        }

@app.get("/doviz-kurlari")
def doviz_kurlari_getir():
    try:
        url = "https://open.er-api.com/v6/latest/USD"
        response = requests.get(url)
        veri = response.json()
        
        try:
            tl_kuru = veri["rates"].get("TRY")
            eur_kuru = veri["rates"].get("EUR")
        except (KeyError, TypeError):
            tl_kuru = None
            eur_kuru = None
            
        return {
            "base": "USD",
            "TRY": tl_kuru,
            "EUR": eur_kuru,
            "durum": "Başarılı"
        }
    except Exception as e:
        return {"durum": "Hata", "detay": str(e)}

@app.post("/abonelik-ekle")
def abonelik_ekle(abonelik: AbonelikModel):
    try:
        baglanti = pyodbc.connect(DB_CONNECTION_STRING)
        cursor = baglanti.cursor()
        
        sorgu = """
            INSERT INTO Abonelikler (AbonelikAdi, Kategori, Ucret, ParaBirimi, BaslangicTarihi, YenilemePeriyodu)
            VALUES (?, ?, ?, ?, ?, ?)
        """
        cursor.execute(sorgu, (
            abonelik.AbonelikAdi,
            abonelik.Kategori,
            abonelik.Ucret,
            abonelik.ParaBirimi,
            abonelik.BaslangicTarihi,
            abonelik.YenilemePeriyodu
        ))
        
        baglanti.commit()
        baglanti.close()
        
        return {
            "durum": "Başarılı",
            "mesaj": f"'{abonelik.AbonelikAdi}' adlı abonelik başarıyla veritabanına kaydedildi!"
        }
    except Exception as e:
        return {
            "durum": "Hata",
            "mesaj": "Abonelik veritabanına kaydedilemedi!",
            "detay": str(e)
        }

@app.get("/abonelikleri-getir")
def abonelikleri_getir():
    try:
        baglanti = pyodbc.connect(DB_CONNECTION_STRING)
        cursor = baglanti.cursor()
        
        cursor.execute("SELECT Id, AbonelikAdi, Kategori, Ucret, ParaBirimi, BaslangicTarihi, YenilemePeriyodu FROM Abonelikler")
        satirlar = cursor.fetchall()
        
        abonelikler_listesi = []
        for satir in satirlar:
            abonelikler_listesi.append({
                "Id": satir[0],
                "AbonelikAdi": satir[1],
                "Kategori": satir[2],
                "Ucret": float(satir[3]),
                "ParaBirimi": satir[4],
                "BaslangicTarihi": str(satir[5]),
                "YenilemePeriyodu": satir[6]
            })
            
        baglanti.close()
        return {
            "durum": "Başarılı",
            "veri": abonelikler_listesi
        }
    except Exception as e:
        return {
            "durum": "Hata",
            "mesaj": "Abonelikler listelenemedi!",
            "detay": str(e)
        }