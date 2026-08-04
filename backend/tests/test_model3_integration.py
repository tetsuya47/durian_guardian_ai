"""Integration & Unit tests for Model 3 (Random Forest Disease Risk Prediction)."""
import pytest
from app.ai.predictor_model3 import Model3Predictor
from app.services.risk_prediction_service import RiskPredictionService


def test_model3_predictor_initialization():
    """Verify Model3Predictor initializes and loads artifacts cleanly."""
    predictor = Model3Predictor()
    assert predictor._model is not None
    assert predictor._preprocessor is not None
    assert len(predictor._feature_columns) == 14


def test_model3_predictor_inference():
    """Test Model 3 prediction with sample feature inputs."""
    predictor = Model3Predictor()
    sample_data = {
        "temperature": 29.0,
        "humidity": 85.0,
        "rainfall": 40.0,
        "tree_age": 5,
        "variety": "Monthong",
        "health_status": "Khỏe mạnh",
        "predicted_disease": "Khỏe mạnh",
        "confidence": 85.0,
        "season": "Mưa",
        "density_per_hectare": 50.0,
        "days_since_last_inspection": 15,
        "days_since_last_treatment": 30,
        "historical_disease_count": 1,
        "historical_disease_frequency": 0.2,
    }

    result = predictor.predict(sample_data)
    assert "risk_level" in result
    assert "risk_score" in result
    assert "probabilities" in result
    assert "top_factors" in result
    assert isinstance(result["risk_score"], float)
    assert 0.0 <= result["risk_score"] <= 1.0
    assert len(result["top_factors"]) == 5


@pytest.mark.asyncio
async def test_risk_prediction_service_mock_db():
    """Test RiskPredictionService with async mock MongoDB instance."""
    from unittest.mock import AsyncMock, MagicMock

    db_mock = MagicMock()
    service = RiskPredictionService(db_mock)

    # Mock weather service response
    service.weather_service.get_current_weather = AsyncMock(return_value={
        "temp_celsius": 29.5,
        "humidity_percent": 88,
        "rainfall_mm": 25.0,
    })

    result = await service.predict_tree_risk(lat=12.6667, lon=108.0500)
    assert "risk_level" in result
    assert "fungal_disease_risk" in result
    assert result["fungal_disease_risk"] in ("LOW", "MEDIUM", "HIGH")
    assert "weather_used" in result
    assert result["weather_used"]["temperature"] == 29.5
