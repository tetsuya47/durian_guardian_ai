# Model 1: Durian Disease Detection

## Overview

This folder contains everything needed to deploy the Durian Disease Detection model for production inference.

## Files

| File | Description |
|------|-------------|
| `model.pt` | PyTorch model checkpoint (state_dict) |
| `model.torchscript` | TorchScript traced model for C++/mobile deployment |
| `model.onnx` | ONNX model for cross-platform inference |
| `config.yaml` | Model configuration (hyperparameters) |
| `class_names.txt` | List of 10 disease class names |

## Inference

### Python (PyTorch)

```python
from training.predict import predict

result = predict("leaf.jpg")
print(result["predicted_class"], result["confidence"])
```

### Python (ONNX Runtime)

```python
import onnxruntime as ort
import numpy as np
from PIL import Image

session = ort.InferenceSession("model.onnx")
input_name = session.get_inputs()[0].name

img = Image.open("leaf.jpg").resize((224, 224))
x = np.array(img).astype(np.float32) / 255.0
x = (x - [0.485, 0.456, 0.406]) / [0.229, 0.224, 0.225]
x = x.transpose(2, 0, 1)[np.newaxis, ...]

outputs = session.run(None, {input_name: x})
pred_class = outputs[0].argmax()
```

### C++ (TorchScript)

```cpp
#include <torch/script.h>
#include <torch/torch.h>

int main() {
    torch::jit::script::Module module;
    module = torch::jit::load("model.torchscript");
    torch::Tensor input = torch::randn({1, 3, 224, 224});
    auto output = module.forward({input}).toTensor();
    auto pred = output.argmax(1);
    return 0;
}
```

## FastAPI Backend

See `api_schema.json` for the complete API specification.

```python
from fastapi import FastAPI, File, UploadFile
from training.predict import predict

app = FastAPI()

@app.post("/predict")
async def predict_endpoint(image: UploadFile = File(...)):
    result = predict(image.file)
    return result
```

## Metrics

- Test Accuracy: **89.51%**
- F1 Score: **89.39%**
- ROC-AUC: **99.19%**
- Top-5 Accuracy: **99.38%**
