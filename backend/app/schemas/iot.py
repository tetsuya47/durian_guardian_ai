from __future__ import annotations

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class IoTEstimateRequest(BaseModel):
    area_hectare: float = Field(..., gt=0, description="Diện tích trang trại (ha)")
    tree_count: int = Field(..., ge=0, description="Số lượng cây")
    zone_count: int = Field(default=1, ge=1, description="Số khu vực (Zone)")


class IoTDeviceRecommendation(BaseModel):
    device_type: str
    device_name: str
    recommended_quantity: int
    unit_price: float
    description: str


class IoTEstimateResponse(BaseModel):
    area_hectare: float
    tree_count: int
    zone_count: int
    recommendations: List[IoTDeviceRecommendation]
    total_estimated_cost: float


class IoTOrderItem(BaseModel):
    device_type: str
    device_name: str
    quantity: int
    unit_price: float


class IoTOrderCreate(BaseModel):
    farm_id: Optional[str] = None
    farm_name: str
    area_hectare: float
    tree_count: int
    items: List[IoTOrderItem]
    notes: Optional[str] = None


class IoTOrderStatusUpdate(BaseModel):
    status: str = Field(..., description="Pending, Approved, Paid, Shipping, Delivered, Cancelled")
    admin_notes: Optional[str] = None


class IoTOrderOut(BaseModel):
    id: str
    order_code: str
    user_id: str
    user_name: Optional[str] = None
    farm_id: Optional[str] = None
    farm_name: str
    area_hectare: float
    tree_count: int
    items: List[IoTOrderItem]
    total_amount: float
    status: str
    notes: Optional[str] = None
    admin_notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
