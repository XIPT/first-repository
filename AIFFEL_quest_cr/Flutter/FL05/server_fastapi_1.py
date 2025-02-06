# server_fastapi_1.py
import uvicorn   # pip install uvicorn 
from fastapi import FastAPI   # pip install fastapi 
from fastapi.middleware.cors import CORSMiddleware # cors issue
import random

# Create the FastAPI application
app = FastAPI()

# cors 이슈
origins = ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# A simple example of a GET request
@app.get("/") # 
def read_root():
    return "Hello 아이펠"

@app.get('/example')
async def root():
    return {"example":"This is example", "data": 0}

@app.get('/example/random')
async def get_random():
    rn : int = random.randint(0,100)
    return {"number":rn, "limit": 100}

@app.get('/example/random/{limit}')
async def get_random(limit:int):
    rn : int = random.randint(0,limit)
    return {"number":rn, "limit": limit}

# Run the server
if __name__ == "__main__":
    uvicorn.run("server_fastapi_1:app",
            reload= True,   # Reload the server when code changes
            host="127.0.0.1",   # Listen on localhost 
            port=5000,   # Listen on port 5000 
            log_level="info"   # Log level
            )