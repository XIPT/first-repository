import uvicorn   # pip install uvicorn 
from fastapi import FastAPI, HTTPException   # pip install fastapi 
from fastapi.middleware.cors import CORSMiddleware
import vgg16_prediction_model
import logging

# Create the FastAPI application
app = FastAPI()

# CORS configuration
origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load the model once
try:
    vgg16_model = vgg16_prediction_model.load_model()
except Exception as e:
    logger.error("Failed to load model: %s", e)
    raise

# A simple example of a GET request
@app.get("/")
async def read_root():
    logger.info("Root URL was requested")
    return "VGG16모델을 사용하는 API를 만들업 봅시다."

@app.get('/sample')
async def sample_prediction():
    try:
        result = await vgg16_prediction_model.prediction_model(vgg16_model)
        logger.info("Prediction was requested and done")
        return result
    except Exception as e:
        logger.error("Prediction failed: %s", e)
        raise HTTPException(status_code=500, detail="Internal Server Error")

# Run the server
if __name__ == "__main__":
    uvicorn.run("server_fastapi_vgg16:app",
            reload= True,   # Reload the server when code changes
            host="127.0.0.1",   # Listen on localhost 
            port=5000,   # Listen on port 5000 
            log_level="info"   # Log level
            )