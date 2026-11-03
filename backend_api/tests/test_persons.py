import os
import subprocess
import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, create_engine, select

from app import database
from app.database import get_session
from app.main import app
from app.models import Person
from app.seed import seed_persons

DATA = dict(fullName="Ayşe Kaya", department="Tasarım", photoUrl="", birthPlace="İzmir", birthDate="1998-07-21", email="ayse@example.com", phone="+905551112233")
FIELDS = set(DATA) | {"id"}


@pytest.fixture
def client(tmp_path, monkeypatch):
    test_engine = create_engine(f"sqlite:///{(tmp_path / 'test.db').as_posix()}", connect_args={"check_same_thread": False})
    # lifespan dahil tüm DB erişimleri geçici dosyaya yönelir.
    monkeypatch.setattr(database, "engine", test_engine)

    def test_session():
        with Session(test_engine) as session:
            yield session

    app.dependency_overrides[get_session] = test_session
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
    test_engine.dispose()


def test_crud_contract(client):
    response = client.get("/api/persons")
    assert response.status_code == 200 and response.json() == []
    response = client.post("/api/persons", json=DATA)
    assert response.status_code == 201
    saved = response.json()
    assert set(saved) == FIELDS
    assert {k: saved[k] for k in DATA} == DATA
    id = saved["id"]
    assert isinstance(id, int)
    assert client.get(f"/api/persons/{id}").json() == saved
    assert client.get("/api/persons").json() == [saved]
    changed = {**DATA, "fullName": "Ayşe Deniz", "department": "Mühendislik", "birthDate": "2000-02-29"}
    response = client.put(f"/api/persons/{id}", json=changed)
    assert response.status_code == 200
    assert set(response.json()) == FIELDS
    assert response.json() == {**changed, "id": id}
    assert client.get(f"/api/persons/{id}").json() == response.json()
    assert client.get("/api/persons").json() == [response.json()]
    response = client.delete(f"/api/persons/{id}")
    assert response.status_code == 204 and response.content == b""
    assert client.get(f"/api/persons/{id}").status_code == 404
    assert client.get("/api/persons").json() == []


@pytest.mark.parametrize("change", [
    {"fullName": " "}, {"department": ""}, {"birthPlace": " "},
    {"birthDate": "2023-02-29"}, {"birthDate": "2999-01-01"},
    {"birthDate": "1998-07-21T00:00:00"}, {"birthDate": 0},
    {"email": "invalid"}, {"phone": "abc1234"}, {"phone": "+12"}, {"id": 55},
])
def test_invalid_data(client, change):
    assert client.post("/api/persons", json={**DATA, **change}).status_code == 422


def test_missing_fields_and_atomic_invalid_put(client):
    assert client.post("/api/persons", json={}).status_code == 422
    original = client.post("/api/persons", json=DATA).json()
    path = f"/api/persons/{original['id']}"
    assert client.put(path, json={"fullName": "Yeni İsim"}).status_code == 422
    assert client.put(path, json={**DATA, "email": "wrong"}).status_code == 422
    assert client.get(path).json() == original


def test_not_found(client):
    assert client.get("/api/persons/99999").status_code == 404
    assert client.put("/api/persons/99999", json=DATA).status_code == 404
    assert client.delete("/api/persons/99999").status_code == 404


def test_optional_photo_and_trim(client):
    data = {k: v for k, v in DATA.items() if k != "photoUrl"}
    data["fullName"] = "  Ayşe Kaya  "
    response = client.post("/api/persons", json=data)
    assert response.status_code == 201
    assert response.json()["photoUrl"] == ""
    assert response.json()["fullName"] == "Ayşe Kaya"


def test_seed_idempotent(client):
    with Session(database.engine) as session:
        assert seed_persons(session) == 3
        assert seed_persons(session) == 0
        assert len(session.exec(select(Person)).all()) == 3


def test_seed_command_and_persistence(tmp_path):
    url = f"sqlite:///{(tmp_path / 'seed.db').as_posix()}"
    env = {**os.environ, "DATABASE_URL": url, "PYTHONIOENCODING": "utf-8"}
    for _ in range(2):
        subprocess.run([sys.executable, "-m", "app.seed"], env=env, cwd=Path(__file__).resolve().parents[1], check=True, capture_output=True)
    other_engine = create_engine(url)
    with Session(other_engine) as session:
        assert len(session.exec(select(Person)).all()) == 3
    other_engine.dispose()


def test_docs_and_exact_routes(client):
    assert client.get("/docs").status_code == 200
    schema = client.get("/openapi.json").json()
    assert set(schema["paths"]) == {"/api/persons", "/api/persons/{id}"}
    assert sum(len(methods) for methods in schema["paths"].values()) == 5
