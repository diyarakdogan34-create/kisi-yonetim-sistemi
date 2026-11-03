import re
from datetime import date

from pydantic import ConfigDict, EmailStr, field_validator
from sqlmodel import Field, SQLModel


class PersonBase(SQLModel):
    fullName: str = Field(min_length=2, max_length=100)
    department: str = Field(min_length=1, max_length=100)
    photoUrl: str = Field(default="", max_length=2048)
    birthPlace: str = Field(min_length=1, max_length=100)
    birthDate: date
    email: str = Field(max_length=254)
    phone: str = Field(min_length=7, max_length=30)


class Person(PersonBase, table=True):
    id: int | None = Field(default=None, primary_key=True)


class PersonCreate(PersonBase):
    model_config = ConfigDict(extra="forbid")
    email: EmailStr = Field(max_length=254)

    @field_validator("fullName", "department", "birthPlace", "email", "phone", "photoUrl", mode="before")
    @classmethod
    def trim_text(cls, value):
        return value.strip() if isinstance(value, str) else value

    @field_validator("birthDate", mode="before")
    @classmethod
    def iso_date_only(cls, value):
        if isinstance(value, str) and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
            raise ValueError("Doğum tarihi YYYY-MM-DD biçiminde olmalıdır.")
        if not isinstance(value, (str, date)):
            raise ValueError("Geçerli bir doğum tarihi girin.")
        return value

    @field_validator("birthDate")
    @classmethod
    def valid_birth_date(cls, value):
        if value > date.today() or value < date(1900, 1, 1):
            raise ValueError("Doğum tarihi 1900 ile bugün arasında olmalıdır.")
        return value

    @field_validator("phone")
    @classmethod
    def valid_phone(cls, value):
        digits = re.sub(r"\D", "", value)
        if not re.fullmatch(r"\+?[0-9 ()-]+", value) or not 7 <= len(digits) <= 15:
            raise ValueError("Telefon 7–15 rakam içermelidir.")
        return value


class PersonUpdate(PersonCreate):
    """PUT, formun tüm zorunlu alanlarını yeniden ister."""


class PersonRead(PersonBase):
    id: int
