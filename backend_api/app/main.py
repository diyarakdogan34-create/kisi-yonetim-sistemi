from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, Request, Response
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlmodel import Session, select

from .database import create_db_and_tables, get_session
from .models import Person, PersonCreate, PersonRead, PersonUpdate


@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    yield


app = FastAPI(title="Kişi Yönetim Sistemi", version="1.0.0", lifespan=lifespan)


@app.exception_handler(RequestValidationError)
async def validation_error(request: Request, exc: RequestValidationError):
    # 422 ve standart detail listesi korunur; kullanıcıya Türkçe mesaj verilir.
    messages = {
        "missing": "Bu alan zorunludur.",
        "extra_forbidden": "Bu alan gönderilemez.",
        "string_too_short": "Bu alan boş veya çok kısa.",
        "string_too_long": "Bu alan izin verilenden uzun.",
        "json_invalid": "Geçerli bir JSON gövdesi gönderin.",
    }
    details = []
    for error in exc.errors():
        field = error["loc"][-1] if error["loc"] else "body"
        message = messages.get(error["type"], "Geçerli bir değer girin.")
        if error["type"] not in messages:
            message = {"email": "Geçerli bir e-posta adresi girin.",
                       "birthDate": "1900 ile bugün arasında YYYY-MM-DD biçiminde tarih girin.",
                       "phone": "Telefon 7–15 rakam içermelidir."}.get(field, message)
        details.append({"loc": error["loc"], "type": error["type"], "msg": message})
    return JSONResponse(status_code=422, content={"detail": details})


def find_person(person_id: int, session: Session) -> Person:
    person = session.get(Person, person_id)
    if person is None:
        raise HTTPException(status_code=404, detail="Kişi bulunamadı. Silinmiş olabilir.")
    return person


@app.get("/api/persons", response_model=list[PersonRead], tags=["Kişiler"])
def get_persons(session: Session = Depends(get_session)):
    return session.exec(select(Person).order_by(Person.id)).all()


@app.get("/api/persons/{id}", response_model=PersonRead, tags=["Kişiler"])
def get_person(id: int, session: Session = Depends(get_session)):
    return find_person(id, session)


@app.post("/api/persons", response_model=PersonRead, status_code=201, tags=["Kişiler"])
def create_person(data: PersonCreate, session: Session = Depends(get_session)):
    person = Person.model_validate(data)
    session.add(person)
    session.commit()
    session.refresh(person)
    return person


@app.put("/api/persons/{id}", response_model=PersonRead, tags=["Kişiler"])
def update_person(id: int, data: PersonUpdate, session: Session = Depends(get_session)):
    person = find_person(id, session)
    for field, value in data.model_dump().items():
        setattr(person, field, value)
    session.add(person)
    session.commit()
    session.refresh(person)
    return person


@app.delete("/api/persons/{id}", status_code=204, tags=["Kişiler"])
def delete_person(id: int, session: Session = Depends(get_session)):
    person = find_person(id, session)
    session.delete(person)
    session.commit()
    return Response(status_code=204)
