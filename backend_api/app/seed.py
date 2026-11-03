import sys

from sqlmodel import Session, select

from .database import create_db_and_tables, engine
from .models import Person, PersonCreate

SAMPLE_PERSONS = [
    dict(fullName="Ayşe Kaya", department="İnsan Kaynakları", photoUrl="https://i.pravatar.cc/150?img=47", birthPlace="İstanbul", birthDate="1998-07-21", email="ayse.kaya@sirket.com", phone="+905551112233"),
    dict(fullName="Ahmet Yılmaz", department="Yazılım Geliştirme", photoUrl="https://i.pravatar.cc/150?img=12", birthPlace="Adana", birthDate="1994-04-12", email="ahmet.yilmaz@sirket.com", phone="+905550123456"),
    dict(fullName="Deniz Demir", department="Ürün Tasarımı", photoUrl="", birthPlace="İzmir", birthDate="1996-11-03", email="deniz.demir@sirket.com", phone="+905559876543"),
]


def seed_persons(session: Session) -> int:
    added = 0
    for data in SAMPLE_PERSONS:
        if session.exec(select(Person).where(Person.email == data["email"])).first() is None:
            person = Person.model_validate(PersonCreate.model_validate(data))
            session.add(person)
            added += 1
    session.commit()
    return added


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    create_db_and_tables()
    with Session(engine) as session:
        print(f"{seed_persons(session)} örnek kişi eklendi.")
