from fastapi import FastAPI

app = FastAPI()

@app.get("/api/sales")
def get_sales():
    return {"message": "Sales data will be here!"}