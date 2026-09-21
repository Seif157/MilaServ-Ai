from fastapi import FastAPI

app = FastAPI(title="HR Assistant — understanding service")


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}
