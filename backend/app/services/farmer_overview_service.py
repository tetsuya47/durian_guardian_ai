from __future__ import annotations

import asyncio
import logging
from datetime import datetime

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.exceptions import NotFoundException
from app.repositories import UserRepository
from app.repositories.neighbor_contact_request_repository import NeighborContactRequestRepository
from app.schemas.farmer_overview import (
    ActivityDTO,
    AddressDTO,
    AlertOverviewDTO,
    DetectionStatsDTO,
    FarmOverviewDTO,
    FarmerOverviewDTO,
    FarmerProfileDTO,
    InspectionOverviewDTO,
    InspectionStatsDTO,
    NeighborOverviewDTO,
)

logger = logging.getLogger(__name__)

FARM_OWNER_ROLE = "Farm Owner"
HEALTHY_PREDICTION = "Khỏe mạnh"

PRIORITY_TO_LEVEL = {
    "Cao": "critical",
    "Trung bình": "warning",
    "Thấp": "normal",
}


class FarmerOverviewService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.user_repo = UserRepository(db)
        self.ncr_repo = NeighborContactRequestRepository(db)

    async def get_overview(self, user_id: str) -> FarmerOverviewDTO:
        user_oid = ObjectId(user_id) if ObjectId.is_valid(user_id) else None
        if user_oid is None:
            raise NotFoundException("User not found")

        user = await self.db["users"].find_one({"_id": user_oid})
        if not user:
            raise NotFoundException("User not found")
        if user.get("role") != FARM_OWNER_ROLE:
            raise NotFoundException("User is not a Farm Owner")

        farms = []
        async for f in self.db["farms"].find({"owner_user_id": user_oid}).sort("farm_code", 1):
            farms.append(f)
        farm_oids = [f["_id"] for f in farms]
        farm_ids_match = {"$in": farm_oids} if farm_oids else {"$in": []}

        (
            zone_count,
            tree_count,
            inspection_stats,
            detection_stats,
            alert_counts,
            ncr_status,
            ncr_direction,
        ) = await asyncio.gather(
            self.db["zones"].count_documents({"farm_id": farm_ids_match}),
            self.db["trees"].count_documents({"farm_id": farm_ids_match}),
            self._get_inspection_stats(farm_ids_match),
            self._get_detection_stats(farm_ids_match),
            self._get_alert_counts(farm_ids_match),
            self.ncr_repo.count_by_status(user_oid),
            self.ncr_repo.count_by_direction(user_oid),
        )

        company_names = await self._get_company_names(farms)

        (
            inspection_events,
            detection_events,
            alert_events,
            ncr_events,
        ) = await asyncio.gather(
            self._get_inspection_events(farm_ids_match),
            self._get_detection_events(farm_ids_match),
            self._get_alert_events(farm_ids_match),
            self._get_ncr_events(user_oid),
        )

        activities = self._merge_activities(
            inspection_events + detection_events + alert_events + ncr_events,
            limit=20,
        )

        farm_name = farms[0].get("farm_name") if farms else None
        company_id = farms[0].get("company_id") if farms else None
        company_name = (
            company_names.get(str(company_id)) if company_id else None
        )

        return FarmerOverviewDTO(
            profile=FarmerProfileDTO(
                user_id=user_id,
                user_code=user.get("user_code", ""),
                full_name=user.get("full_name", ""),
                email=user.get("email"),
                phone=user.get("phone"),
                role=user.get("role", FARM_OWNER_ROLE),
                status=user.get("status"),
                address=AddressDTO(**user["address"]) if user.get("address") else None,
                avatar=None,
                farm_name=farm_name,
                company_name=company_name,
                created_at=user.get("created_at"),
            ),
            farm=FarmOverviewDTO(
                total_farms=len(farms),
                total_zones=zone_count,
                total_trees=tree_count,
                total_area_hectare=round(sum(f.get("area_hectare") or 0 for f in farms), 2),
                districts=sorted({f.get("district") for f in farms if f.get("district")}),
            ),
            inspection=InspectionOverviewDTO(
                inspection=InspectionStatsDTO(
                    total_inspections=inspection_stats["total"],
                    last_inspection=inspection_stats["last"],
                ),
                detection=DetectionStatsDTO(
                    healthy=detection_stats["healthy"],
                    diseased=detection_stats["diseased"],
                    detection_rate=(
                        round((detection_stats["diseased"] / tree_count) * 100, 1)
                        if tree_count > 0
                        else 0.0
                    ),
                ),
            ),
            alerts=AlertOverviewDTO(
                total_alerts=sum(alert_counts["raw"].values()),
                critical=alert_counts.get("critical", 0),
                warning=alert_counts.get("warning", 0),
                normal=alert_counts.get("normal", 0),
                raw_priority=alert_counts.get("raw", {}),
            ),
            neighbor=NeighborOverviewDTO(
                sent_requests=ncr_direction[0],
                received_requests=ncr_direction[1],
                pending=ncr_status.get("pending", 0),
                waiting_source_consent=ncr_status.get("waiting_source_consent", 0),
                waiting_target_consent=ncr_status.get("waiting_target_consent", 0),
                contact_shared=ncr_status.get("contact_shared", 0),
                rejected=ncr_status.get("rejected", 0),
                cancelled=ncr_status.get("cancelled", 0),
            ),
            activities=activities,
        )

    async def _get_inspection_stats(self, farm_match: dict) -> dict:
        pipeline = [
            {"$match": {"farm_id": farm_match}},
            {
                "$group": {
                    "_id": None,
                    "total": {"$sum": 1},
                    "last": {"$max": "$inspection_date"},
                }
            },
        ]
        cursor = self.db["inspections"].aggregate(pipeline)
        docs = await cursor.to_list(length=1)
        if not docs:
            return {"total": 0, "last": None}
        return {"total": docs[0].get("total", 0), "last": docs[0].get("last")}

    async def _get_detection_stats(self, farm_match: dict) -> dict:
        pipeline = [
            {
                "$lookup": {
                    "from": "inspections",
                    "localField": "inspection_id",
                    "foreignField": "_id",
                    "as": "inspection_info",
                }
            },
            {"$unwind": "$inspection_info"},
            {"$match": {"inspection_info.farm_id": farm_match}},
            {
                "$group": {
                    "_id": None,
                    "total": {"$sum": 1},
                    "healthy": {
                        "$sum": {
                            "$cond": [{"$eq": ["$prediction", HEALTHY_PREDICTION]}, 1, 0]
                        }
                    },
                }
            },
        ]
        cursor = self.db["detection_results"].aggregate(pipeline)
        docs = await cursor.to_list(length=1)
        if not docs:
            return {"healthy": 0, "diseased": 0}
        total = docs[0].get("total", 0)
        healthy = docs[0].get("healthy", 0)
        return {"healthy": healthy, "diseased": total - healthy}

    async def _get_alert_counts(self, farm_match: dict) -> dict:
        pipeline = [
            {"$match": {"farm_id": farm_match}},
            {"$group": {"_id": "$priority", "count": {"$sum": 1}}},
        ]
        cursor = self.db["alerts"].aggregate(pipeline)
        counts: dict = {"critical": 0, "warning": 0, "normal": 0, "raw": {}}
        async for doc in cursor:
            key = doc["_id"]
            counts["raw"][str(key)] = int(doc["count"])
            level = PRIORITY_TO_LEVEL.get(str(key))
            if level:
                counts[level] += int(doc["count"])
        return counts

    async def _get_company_names(self, farms: list[dict]) -> dict:
        company_ids = {f.get("company_id") for f in farms if f.get("company_id")}
        result: dict = {}
        if not company_ids:
            return result
        cursor = self.db["companies"].find({"_id": {"$in": list(company_ids)}})
        async for c in cursor:
            result[str(c["_id"])] = c.get("company_name")
        return result

    async def _get_inspection_events(self, farm_match: dict) -> list[ActivityDTO]:
        pipeline = [
            {"$match": {"farm_id": farm_match}},
            {"$sort": {"inspection_date": -1}},
            {"$limit": 10},
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "tree_id",
                    "foreignField": "_id",
                    "as": "tree_info",
                }
            },
            {"$unwind": {"path": "$tree_info", "preserveNullAndEmptyArrays": True}},
            {
                "$project": {
                    "_id": 1,
                    "inspection_code": 1,
                    "tree_code": "$tree_info.tree_code",
                    "predicted_disease": 1,
                    "inspection_date": 1,
                }
            },
        ]
        items = []
        async for doc in self.db["inspections"].aggregate(pipeline):
            tree_code = doc.get("tree_code") or "—"
            disease = doc.get("predicted_disease") or HEALTHY_PREDICTION
            items.append(
                ActivityDTO(
                    type="Inspection Created",
                    source="inspection",
                    timestamp=doc["inspection_date"],
                    entity_id=str(doc["_id"]),
                    entity_code=doc.get("inspection_code"),
                    detail=f"Cây {tree_code} – {disease}",
                )
            )
        return items

    async def _get_detection_events(self, farm_match: dict) -> list[ActivityDTO]:
        pipeline = [
            {
                "$lookup": {
                    "from": "inspections",
                    "localField": "inspection_id",
                    "foreignField": "_id",
                    "as": "inspection_info",
                }
            },
            {"$unwind": {"path": "$inspection_info", "preserveNullAndEmptyArrays": False}},
            {"$match": {"inspection_info.farm_id": farm_match}},
            {"$sort": {"created_at": -1}},
            {"$limit": 10},
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "inspection_info.tree_id",
                    "foreignField": "_id",
                    "as": "tree_info",
                }
            },
            {"$unwind": {"path": "$tree_info", "preserveNullAndEmptyArrays": True}},
            {
                "$project": {
                    "_id": 1,
                    "detection_code": 1,
                    "prediction": 1,
                    "confidence": 1,
                    "tree_code": "$tree_info.tree_code",
                    "created_at": 1,
                }
            },
        ]
        items = []
        async for doc in self.db["detection_results"].aggregate(pipeline):
            tree_code = doc.get("tree_code") or "—"
            confidence = doc.get("confidence") or 0
            items.append(
                ActivityDTO(
                    type="AI Detection Completed",
                    source="detection",
                    timestamp=doc["created_at"],
                    entity_id=str(doc["_id"]),
                    entity_code=doc.get("detection_code"),
                    detail=f"Cây {tree_code} – {doc.get('prediction')} (độ tin cậy {round(float(confidence), 1)}%)",
                )
            )
        return items

    async def _get_alert_events(self, farm_match: dict) -> list[ActivityDTO]:
        pipeline = [
            {"$match": {"farm_id": farm_match}},
            {"$sort": {"date": -1}},
            {"$limit": 10},
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "tree_id",
                    "foreignField": "_id",
                    "as": "tree_info",
                }
            },
            {"$unwind": {"path": "$tree_info", "preserveNullAndEmptyArrays": True}},
            {
                "$project": {
                    "_id": 1,
                    "alert_code": 1,
                    "alert_type": 1,
                    "priority": 1,
                    "tree_code": "$tree_info.tree_code",
                    "date": 1,
                }
            },
        ]
        items = []
        async for doc in self.db["alerts"].aggregate(pipeline):
            tree_code = doc.get("tree_code") or "—"
            items.append(
                ActivityDTO(
                    type="Alert Generated",
                    source="alert",
                    timestamp=doc["date"],
                    entity_id=str(doc["_id"]),
                    entity_code=doc.get("alert_code"),
                    detail=f"{doc.get('alert_type')} – {doc.get('priority')} (cây {tree_code})",
                )
            )
        return items

    async def _get_ncr_events(self, user_oid: ObjectId) -> list[ActivityDTO]:
        docs = await self.ncr_repo.list_latest(user_oid, limit=10)
        items = []
        for doc in docs:
            items.append(self._build_ncr_activity(doc, user_oid))
        return items

    def _build_ncr_activity(self, doc: dict, user_oid: ObjectId) -> ActivityDTO:
        is_source = doc.get("source_user_id") == user_oid
        status = doc.get("status")
        other_farm = doc.get("target_farm_name") if is_source else doc.get("source_farm_name")

        if doc.get("contact_shared"):
            event_type = "Contact Shared"
        elif status == "rejected":
            event_type = "Request Rejected"
        elif status == "cancelled":
            event_type = "Request Cancelled"
        elif status == "pending":
            event_type = "Request Sent" if is_source else "Request Received"
        elif status == "waiting_target_consent":
            event_type = "Awaiting Consent" if is_source else "Consent Required"
        elif status == "waiting_source_consent":
            event_type = "Consent Required" if is_source else "Awaiting Consent"
        else:
            event_type = "Request Updated"

        timestamp = (
            doc.get("shared_at") or doc.get("updated_at") or doc.get("created_at")
        )
        return ActivityDTO(
            type=event_type,
            source="neighbor",
            timestamp=timestamp,
            entity_id=doc.get("id"),
            entity_code=doc.get("request_code"),
            detail=f"Trang trại {other_farm or '—'} – {status or '—'}",
        )

    def _merge_activities(self, events: list[ActivityDTO], limit: int = 20) -> list[ActivityDTO]:
        source_priority = {"inspection": 1, "detection": 2, "alert": 3, "neighbor": 4}
        events.sort(
            key=lambda e: (
                e.timestamp or datetime.min,
                -source_priority.get(e.source, 9),
            ),
            reverse=True,
        )
        return events[:limit]
