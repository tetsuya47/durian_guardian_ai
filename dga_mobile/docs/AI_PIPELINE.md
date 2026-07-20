# AI Diagnosis Pipeline — Processing Workflow

This document explains the sequential execution blocks of the integrated diagnosis request.

```
  Incoming File Upload -> [1. Quality Check] -(Invalid)-> Terminate (400 Bad Request)
                               │
                            (Valid)
                               ▼
                        [2. Save Image]
                               │
                               ▼
                     [3. Disease Detection] -> predicted class, confidence
                               │
                               ▼
                     [4. DB Feature Lookup] -> tree, farm, history details
                               │
                               ▼
                     [5. Risk Prediction]   -> risk level, probability
                               │
                               ▼
                     [6. Recommendation]    -> urgency, priority, loss%
                               │
                               ▼
                     [7. Grad-CAM Hooks]    -> generate heatmap & overlay
                               │
                               ▼
                     [8. Database Insert]   -> write log in disease_history
                               │
                               ▼
                     [9. Trigger Auto-Alert] -> inserts alerts if Critical
                               │
                               ▼
                     [10. Return Response]  -> unified JSON payload
```

---

## Graceful Fallback Strategies
1. **Model 2 Fails**: Terminate the request and notify the user to take a clearer picture.
2. **Model 1 Fails**: Bypasses downstream blocks and raises an error log.
3. **Model 3 Fails**: The workflow catches the exception, logs a warning, and falls back to **Disease-Only** details.
4. **Model 4 Fails**: The workflow catches the exception, logs a warning, and falls back to **Disease + Risk** details.
